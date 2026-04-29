$env:PATH = "C:\msys64\ucrt64\bin;C:\msys64\usr\bin;$env:PATH"
$env:VERILATOR_ROOT = "C:\msys64\ucrt64\share\verilator"

Write-Host "Verilog tools are available in this PowerShell session:"
iverilog -V | Select-Object -First 1
verilator_bin.exe --version
