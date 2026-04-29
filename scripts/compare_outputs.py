from pathlib import Path
import math


ROOT = Path(__file__).resolve().parents[1]
PY_DIR = ROOT / "output_python"
CPP_DIR = ROOT / "output_cpp"
REPORT = ROOT / "comparison_report.txt"


def read_output(path: Path):
    shape = None
    values = []
    in_values = False
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("Shape"):
                left = line.find("[")
                right = line.find("]")
                text = line[left + 1:right].strip()
                shape = [] if not text else [int(x.strip()) for x in text.split(",")]
            elif line == "Values:":
                in_values = True
            elif in_values and ":" in line:
                values.append(float(line.split(":", 1)[1].strip()))
    return shape, values


def main():
    py_layers = sorted(p for p in PY_DIR.iterdir() if p.is_dir())
    cpp_layers = sorted(p for p in CPP_DIR.iterdir() if p.is_dir())
    if len(py_layers) != len(cpp_layers):
        raise SystemExit(f"Layer count differs: python={len(py_layers)} cpp={len(cpp_layers)}")

    lines = []
    lines.append("========================================")
    lines.append("PYTHON VS CPP OUTPUT COMPARISON")
    lines.append("========================================")
    lines.append("")
    lines.append(f"Python folder : {PY_DIR}")
    lines.append(f"C++ folder    : {CPP_DIR}")
    lines.append(f"Layer count   : {len(py_layers)}")
    lines.append("")
    lines.append(f"{'Layer':<42} {'Count':>10} {'MaxAbs':>14} {'MeanAbs':>14} {'Status':>8}")

    global_max = 0.0
    failed = 0
    tolerance = 2e-4
    for py_layer, cpp_layer in zip(py_layers, cpp_layers):
        py_shape, py_values = read_output(py_layer / "output.txt")
        cpp_shape, cpp_values = read_output(cpp_layer / "output.txt")
        name = py_layer.name
        if py_shape != cpp_shape or len(py_values) != len(cpp_values):
            lines.append(f"{name:<42} {'-':>10} {'-':>14} {'-':>14} {'SHAPE':>8}")
            failed += 1
            continue
        diffs = [abs(a - b) for a, b in zip(py_values, cpp_values)]
        max_abs = max(diffs) if diffs else 0.0
        mean_abs = sum(diffs) / len(diffs) if diffs else 0.0
        global_max = max(global_max, max_abs)
        status = "OK" if max_abs <= tolerance else "FAIL"
        if status != "OK":
            failed += 1
        lines.append(f"{name:<42} {len(diffs):>10} {max_abs:>14.8g} {mean_abs:>14.8g} {status:>8}")

    lines.append("")
    lines.append(f"Tolerance      : {tolerance}")
    lines.append(f"Global max abs : {global_max:.10g}")
    lines.append(f"Failed layers  : {failed}")

    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
