from pathlib import Path
import csv
import shutil

import torch
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
IMAGE_DIR = ROOT / "images"
LABELS_CSV = ROOT / "labels.csv"
OUT_DIR = ROOT / "data" / "batch_inputs"
IMG_SIZE = 160


def preprocess_image(image_path: Path) -> torch.Tensor:
    img = Image.open(image_path).convert("RGB").resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)
    raw = torch.frombuffer(bytearray(img.tobytes()), dtype=torch.uint8)
    raw = raw.view(IMG_SIZE, IMG_SIZE, 3).permute(2, 0, 1).float() / 255.0
    mean = torch.tensor([0.485, 0.456, 0.406]).view(3, 1, 1)
    std = torch.tensor([0.229, 0.224, 0.225]).view(3, 1, 1)
    return ((raw - mean) / std).unsqueeze(0).contiguous()


def write_tensor(path: Path, tensor: torch.Tensor, tensor_name: str) -> None:
    values = tensor.detach().cpu().contiguous().view(-1).tolist()
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write("========================================\n")
        f.write("TENSOR DATA\n")
        f.write("========================================\n\n")
        f.write(f"Tensor name : {tensor_name}\n")
        f.write(f"Shape       : {list(tensor.shape)}\n")
        f.write(f"Num values  : {len(values)}\n")
        f.write("Dtype       : float32\n\n")
        f.write("Values:\n")
        for i, value in enumerate(values):
            f.write(f"{i}: {value:.10f}\n")


def main() -> None:
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir(parents=True)

    rows = list(csv.DictReader(LABELS_CSV.open("r", encoding="utf-8")))
    for idx, row in enumerate(rows, 1):
        image_path = IMAGE_DIR / row["filename"]
        if not image_path.exists():
            raise FileNotFoundError(image_path)
        tensor = preprocess_image(image_path)
        write_tensor(OUT_DIR / f"{Path(row['filename']).stem}.txt", tensor, row["filename"])
        if idx % 100 == 0 or idx == len(rows):
            print(f"Prepared {idx}/{len(rows)} inputs")

    print(f"Batch inputs written to {OUT_DIR}")


if __name__ == "__main__":
    main()
