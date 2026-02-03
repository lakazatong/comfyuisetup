# Check if ./app/.cache exists and back it up
if (Test-Path "./app/.cache") {
    Write-Host "Backing up ./app/.cache to ./.cache_backup..."
    if (Test-Path "./.cache_backup") {
        Remove-Item "./.cache_backup" -Recurse -Force
    }
    Move-Item "./app/.cache" "./.cache_backup"
}

# Force remove ./app if it exists
if (Test-Path "./app") {
    Write-Host "Removing ./app..."
    Remove-Item "./app" -Recurse -Force
}

# Download ComfyUI
Write-Host "Downloading ComfyUI v0.11.1..."
$url = "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v0.11.1.zip"
$zipFile = "ComfyUI-0.11.1.zip"
Invoke-WebRequest -Uri $url -OutFile $zipFile

# Unzip to current directory
Write-Host "Extracting archive..."
Expand-Archive -Path $zipFile -DestinationPath "." -Force

# Create ./app directory
New-Item -ItemType Directory -Path "./app" -Force | Out-Null

# Move contents from ./ComfyUI-0.11.1 to ./app
Write-Host "Moving files to ./app..."
Get-ChildItem -Path "./ComfyUI-0.11.1" | Move-Item -Destination "./app" -Force

# Remove the now-empty ComfyUI-0.11.1 folder
Remove-Item "./ComfyUI-0.11.1" -Force

# Restore cache if backup exists
if (Test-Path "./.cache_backup") {
    Write-Host "Restoring cache..."
    Move-Item "./.cache_backup" "./app/.cache"
}

# Cleanup
Write-Host "Cleaning up..."
Remove-Item $zipFile -Force

if (Test-Path "./app/requirements.txt") {
    Remove-Item "./app/requirements.txt" -Force
}

Write-Host "Done!"
