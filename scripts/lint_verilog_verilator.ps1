$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$env:PATH = "C:\msys64\ucrt64\bin;C:\msys64\usr\bin;$env:PATH"
$env:VERILATOR_ROOT = "C:\msys64\ucrt64\share\verilator"

Set-Location $Root

verilator_bin.exe --lint-only -Wall --Wno-fatal `
    -Iverilog/include `
    verilog/rtl/sync_ram_1p.v `
    verilog/rtl/relu_vector.v `
    verilog/rtl/argmax.v `
    verilog/rtl/avgpool_1x1.v `
    verilog/rtl/conv2d_sequential.v `
    verilog/rtl/linear_sequential.v `
    verilog/rtl/animalnet_top_skeleton.v

Write-Host "Verilator lint completed. Review warnings above before synthesis."
