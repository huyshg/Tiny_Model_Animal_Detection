$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Set-Location $Root
python .\scripts\prepare_batch_inputs.py

Set-Location $BuildDir
g++ -std=c++17 -O2 -I ..\cpp\include ..\cpp\batch_accuracy.cpp ..\cpp\src\tensor.cpp ..\cpp\src\tensor_io.cpp ..\cpp\src\layers.cpp ..\cpp\src\model_config.cpp -o batch_accuracy.exe
.\batch_accuracy.exe ..
