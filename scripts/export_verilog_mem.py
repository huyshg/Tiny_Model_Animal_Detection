from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PARAM_DIR = ROOT / "parameters_by_layer_fused"
DATA_DIR = ROOT / "data"
OUT_DIR = ROOT / "verilog" / "mem"

DATA_WIDTH = 32
FRAC_BITS = 16
SCALE = 1 << FRAC_BITS
MIN_VALUE = -(1 << (DATA_WIDTH - 1))
MAX_VALUE = (1 << (DATA_WIDTH - 1)) - 1


def parse_values(path: Path):
    values = []
    in_values = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() == "Values:":
            in_values = True
            continue
        if in_values and ":" in line:
            values.append(float(line.split(":", 1)[1].strip()))
    return values


def quantize(value: float) -> int:
    q = int(round(value * SCALE))
    q = max(MIN_VALUE, min(MAX_VALUE, q))
    if q < 0:
        q = (1 << DATA_WIDTH) + q
    return q


def write_mem(path: Path, values):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        for value in values:
            f.write(f"{quantize(value):08x}\n")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    write_mem(OUT_DIR / "preprocessed_input_q8_16.mem", parse_values(DATA_DIR / "preprocessed_input.txt"))

    for layer_dir in sorted(p for p in PARAM_DIR.iterdir() if p.is_dir()):
        out_layer = OUT_DIR / layer_dir.name
        if (layer_dir / "weight.txt").exists():
            write_mem(out_layer / "weight_q8_16.mem", parse_values(layer_dir / "weight.txt"))
        if (layer_dir / "bias.txt").exists():
            write_mem(out_layer / "bias_q8_16.mem", parse_values(layer_dir / "bias.txt"))

    print(f"Exported Q8.16 .mem files to {OUT_DIR}")


if __name__ == "__main__":
    main()
