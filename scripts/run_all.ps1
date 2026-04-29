$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Set-Location $Root
python .\python\run_python_model_dump.py

Set-Location $BuildDir
g++ -std=c++17 -O2 -I ..\cpp\include ..\cpp\model_inference.cpp ..\cpp\src\*.cpp -o model_inference.exe
.\model_inference.exe

Set-Location $Root
python .\scripts\compare_outputs.py
