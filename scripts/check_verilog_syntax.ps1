$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$env:PATH = "C:\msys64\ucrt64\bin;C:\msys64\usr\bin;$env:PATH"

$BuildDir = Join-Path $Root "build\verilog"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Set-Location $Root

iverilog -g2012 `
    -I .\verilog\include `
    -o .\build\verilog\animalnet_syntax.vvp `
    .\verilog\rtl\sync_ram_1p.v `
    .\verilog\rtl\relu_vector.v `
    .\verilog\rtl\argmax.v `
    .\verilog\rtl\avgpool_1x1.v `
    .\verilog\rtl\conv2d_sequential.v `
    .\verilog\rtl\linear_sequential.v `
    .\verilog\rtl\animalnet_top_skeleton.v

Write-Host "Icarus Verilog syntax check passed."
