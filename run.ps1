# ==================================================================
# x16-PRos -- The x16-PRos run script for Windows (PowerShell)
# Copyright (C) 2025 PRoX2011
# ==================================================================

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Print([string]$color, [string]$msg) {
    $map = @{ "RED"="Red"; "GREEN"="Green"; "YELLOW"="Yellow"; "BLUE"="Cyan"; "NC"="Gray" }
    Write-Host $msg -ForegroundColor ($map[$color])
}

# Source image (project-relative)
$srcImg = "disk_img\x16pros.img"
if (-not (Test-Path $srcImg)) {
    throw "Disk image not found: $srcImg. Run build.ps1 first."
}

# Ensure QEMU is available
if (-not (Get-Command "qemu-system-x86_64" -ErrorAction SilentlyContinue)) {
    throw "qemu-system-x86_64 not found in PATH."
}

# Work around QEMU-on-Windows UNC/share bug:
# copy image to a local temp path (power-of-2 alignment ok)
$tmpDir = Join-Path $env:TEMP "x16pros_run"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$tmpImg = Join-Path $tmpDir "x16pros.img"
Copy-Item -Path $srcImg -Destination $tmpImg -Force

Print "NC" ""
Print "GREEN" "Starting emulator..."

# Use -drive with explicit format and floppy interface
# Audio is optional; remove if it causes issues.
$qemuArgs = @(
    "-drive","file=$tmpImg,if=floppy,format=raw",
    "-boot","a",
    "-audiodev","dsound,id=snd0",
    "-machine","pcspk-audiodev=snd0"
)

& qemu-system-x86_64 @qemuArgs