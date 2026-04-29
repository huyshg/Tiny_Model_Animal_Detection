# AnimalNet Verilog Port

This folder is a hardware-oriented translation of the C++ inference code.

## Fixed-point format

- Data width: signed 32-bit
- Fraction bits: 16
- Format name: Q8.16 style storage
- Multiply result: 64-bit intermediate
- MAC result is shifted right by `FRAC_BITS`

## Folders

- `rtl`: synthesizable Verilog building blocks.
- `include`: shared Verilog constants.
- `mem`: generated fixed-point `.mem` files for input and weights.
- `layer_plan.md`: execution order after Conv2d/BatchNorm2d fusion.

Generate `.mem` files:

```powershell
python .\scripts\export_verilog_mem.py
```

Set Verilog tool PATH for the current PowerShell session:

```powershell
.\scripts\setup_verilog_tools.ps1
```

Run a syntax check with Icarus Verilog:

```powershell
.\scripts\check_verilog_syntax.ps1
```

Run Verilator lint:

```powershell
.\scripts\lint_verilog_verilator.ps1
```

## Notes

The C++ model computes final `softmax`, but hardware classifiers usually only need the largest logit. The Verilog folder therefore provides `argmax.v` instead of a full exponential/division softmax. If exact probabilities are required in hardware, add a LUT or piecewise approximation softmax after `linear_sequential.v`.

The RTL modules are intentionally explicit and loop-counter based so they map cleanly to a future Verilog implementation per layer.

Important files:

- `rtl/conv2d_sequential.v`: grouped/depthwise/pointwise convolution engine.
- `rtl/relu_vector.v`: vector ReLU.
- `rtl/avgpool_1x1.v`: adaptive average pool for the final 10x10 feature map.
- `rtl/linear_sequential.v`: classifier fully-connected layer.
- `rtl/argmax.v`: class selection from logits.
- `rtl/animalnet_top_skeleton.v`: controller map for the complete model. It is intentionally a skeleton so you can choose between one reused compute engine or many parallel layer engines.
