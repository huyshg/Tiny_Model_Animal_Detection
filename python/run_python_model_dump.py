from pathlib import Path
import math
import re
import shutil

import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
WEIGHTS_PATH = ROOT / "animalnet_medium_200k_fixed_weights.pth"
IMAGE_DIR = ROOT / "input_test_picture"
OUTPUT_DIR = ROOT / "output_python"
DATA_DIR = ROOT / "data"
INPUT_TXT = DATA_DIR / "preprocessed_input.txt"
IMG_SIZE = 160


class DepthwisePointwiseBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride):
        super().__init__()
        self.block = nn.Sequential(
            nn.Conv2d(in_channels, in_channels, 3, stride=stride, padding=1, groups=in_channels, bias=False),
            nn.BatchNorm2d(in_channels),
            nn.ReLU(inplace=False),
            nn.Conv2d(in_channels, out_channels, 1, stride=1, padding=0, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=False),
        )


class AnimalNetMedium(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 25, 3, stride=2, padding=1, bias=False),
            nn.BatchNorm2d(25),
            nn.ReLU(inplace=False),
            DepthwisePointwiseBlock(25, 51, stride=1),
            DepthwisePointwiseBlock(51, 76, stride=2),
            DepthwisePointwiseBlock(76, 102, stride=1),
            DepthwisePointwiseBlock(102, 153, stride=2),
            DepthwisePointwiseBlock(153, 204, stride=1),
            DepthwisePointwiseBlock(204, 256, stride=2),
            DepthwisePointwiseBlock(256, 307, stride=1),
        )
        self.pool = nn.AdaptiveAvgPool2d((1, 1))
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(307, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        x = self.pool(x)
        x = self.classifier(x)
        return x


def clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)


def find_image() -> Path:
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    images = sorted(p for p in IMAGE_DIR.iterdir() if p.suffix.lower() in exts)
    if not images:
        raise FileNotFoundError(f"No test image found in {IMAGE_DIR}")
    return images[0]


def preprocess_image(image_path: Path) -> torch.Tensor:
    img = Image.open(image_path).convert("RGB").resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)
    raw = torch.frombuffer(bytearray(img.tobytes()), dtype=torch.uint8)
    raw = raw.view(IMG_SIZE, IMG_SIZE, 3).permute(2, 0, 1).float() / 255.0
    mean = torch.tensor([0.485, 0.456, 0.406]).view(3, 1, 1)
    std = torch.tensor([0.229, 0.224, 0.225]).view(3, 1, 1)
    return ((raw - mean) / std).unsqueeze(0).contiguous()


def safe_name(name: str) -> str:
    return re.sub(r"[^0-9A-Za-z_]+", "_", name).strip("_")


def write_values(path: Path, tensor: torch.Tensor, tensor_name: str) -> None:
    arr = tensor.detach().cpu().contiguous().view(-1).tolist()
    shape = list(tensor.shape)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write("========================================\n")
        f.write("TENSOR DATA\n")
        f.write("========================================\n\n")
        f.write(f"Tensor name : {tensor_name}\n")
        f.write(f"Shape       : {shape}\n")
        f.write(f"Num values  : {len(arr)}\n")
        f.write("Dtype       : float32\n\n")
        f.write("Values:\n")
        for i, value in enumerate(arr):
            f.write(f"{i}: {value:.10f}\n")


def dump_layer(output_index: int, layer_name: str, layer_type: str, tensor: torch.Tensor) -> None:
    folder = OUTPUT_DIR / f"{output_index:03d}_{safe_name(layer_name)}"
    folder.mkdir()
    write_values(folder / "output.txt", tensor, layer_name)
    with (folder / "layer_info.txt").open("w", encoding="utf-8", newline="\n") as f:
        f.write("========================================\n")
        f.write("PYTHON OUTPUT LAYER INFO\n")
        f.write("========================================\n\n")
        f.write(f"Output index : {output_index}\n")
        f.write(f"Layer name   : {layer_name}\n")
        f.write(f"Layer type   : {layer_type}\n")
        f.write(f"Shape        : {list(tensor.shape)}\n")


def main() -> None:
    clean_dir(OUTPUT_DIR)
    DATA_DIR.mkdir(exist_ok=True)

    checkpoint = torch.load(WEIGHTS_PATH, map_location="cpu")
    model = AnimalNetMedium(num_classes=checkpoint["num_classes"])
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    image_path = find_image()
    x = preprocess_image(image_path)
    write_values(INPUT_TXT, x, "preprocessed_input")

    outputs = []
    with torch.no_grad():
        x = model.features[0](x)
        x = model.features[1](x)
        outputs.append(("features.0_fused_features.1", "Conv2d + BatchNorm2d fused", x.clone()))
        x = model.features[2](x)
        outputs.append(("features.2", "ReLU", x.clone()))

        for feature_index in range(3, 10):
            block = model.features[feature_index].block
            x = block[0](x)
            x = block[1](x)
            outputs.append((f"features.{feature_index}.block.0_fused_features.{feature_index}.block.1", "Conv2d + BatchNorm2d fused", x.clone()))
            x = block[2](x)
            outputs.append((f"features.{feature_index}.block.2", "ReLU", x.clone()))
            x = block[3](x)
            x = block[4](x)
            outputs.append((f"features.{feature_index}.block.3_fused_features.{feature_index}.block.4", "Conv2d + BatchNorm2d fused", x.clone()))
            x = block[5](x)
            outputs.append((f"features.{feature_index}.block.5", "ReLU", x.clone()))

        x = model.pool(x)
        outputs.append(("pool", "AdaptiveAvgPool2d", x.clone()))
        x = model.classifier[0](x)
        outputs.append(("classifier.0", "Flatten", x.clone()))
        x = model.classifier[1](x)
        outputs.append(("classifier.1", "Linear", x.clone()))
        x = F.softmax(x, dim=1)
        outputs.append(("softmax", "Softmax", x.clone()))

    for idx, (name, layer_type, tensor) in enumerate(outputs):
        dump_layer(idx, name, layer_type, tensor)

    class_names = checkpoint.get("class_names", [])
    probs = outputs[-1][2][0]
    top_idx = int(torch.argmax(probs).item())
    with (OUTPUT_DIR / "prediction.txt").open("w", encoding="utf-8", newline="\n") as f:
        f.write(f"Image      : {image_path}\n")
        f.write(f"Top index  : {top_idx}\n")
        if class_names:
            f.write(f"Top class  : {class_names[top_idx]}\n")
        f.write(f"Top prob   : {float(probs[top_idx]):.10f}\n")
        f.write("Probabilities:\n")
        for i, prob in enumerate(probs.tolist()):
            label = class_names[i] if i < len(class_names) else str(i)
            f.write(f"{i}: {label}: {prob:.10f}\n")

    print(f"Python outputs written to {OUTPUT_DIR}")
    print(f"Preprocessed input written to {INPUT_TXT}")
    print(f"Dumped {len(outputs)} executable layers")


if __name__ == "__main__":
    main()
