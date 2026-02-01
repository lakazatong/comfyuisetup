# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# URL and paths
$zipUrl = "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v0.11.1.zip"
$zipPath = Join-Path $ScriptDir "ComfyUI.zip"
$extractTemp = Join-Path $ScriptDir "temp_extract"
$appPath = Join-Path $ScriptDir "app"

# Download the zip
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

# Ensure temporary extraction folder exists
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
New-Item -ItemType Directory -Path $extractTemp | Out-Null

# Extract all
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractTemp)

# Ensure app folder exists
if (-not (Test-Path $appPath)) { New-Item -ItemType Directory -Path $appPath | Out-Null }

# Move contents of ComfyUI-0.11.1 to app folder
$sourceFolder = Join-Path $extractTemp "ComfyUI-0.11.1"
Get-ChildItem -Path $sourceFolder -Force | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $appPath -Force
}

# Clean up
Remove-Item $zipPath
Remove-Item $extractTemp -Recurse -Force
Remove-Item "app/requirements.txt"

Write-Output "ComfyUI extracted to $appPath"
