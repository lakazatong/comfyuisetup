# Backup ./app/.cache
$cacheBackup = "./.cache-backup"
if (Test-Path "./app/.cache") {
    Write-Host "Backing up ./app/.cache to $cacheBackup..."
    if (Test-Path $cacheBackup) { Remove-Item $cacheBackup -Recurse -Force }
    Move-Item "./app/.cache" $cacheBackup
}

# Backup ./app/custom_nodes
$customNodesBackup = "./custom_nodes-backup"
if (Test-Path "./app/custom_nodes") {
    Write-Host "Backing up subfolders of ./app/custom_nodes to $customNodesBackup..."
    if (Test-Path $customNodesBackup) { Remove-Item $customNodesBackup -Recurse -Force }
    New-Item -ItemType Directory -Path $customNodesBackup | Out-Null
    Get-ChildItem "./app/custom_nodes" -Directory | ForEach-Object {
        Move-Item $_.FullName "$customNodesBackup/$_"
    }
}

# Force remove ./app if it exists
if (Test-Path "./app") {
    Write-Host "Removing ./app..."
    Remove-Item "./app" -Recurse -Force
}

# Download ComfyUI only if zip doesn't exist
$zipFile = "ComfyUI-0.11.1.zip"
if (-not (Test-Path $zipFile)) {
    Write-Host "Downloading ComfyUI v0.11.1..."
    $url = "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v0.11.1.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipFile
} else {
    Write-Host "Using existing $zipFile..."
}

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

# Restore .cache
if (Test-Path $cacheBackup) {
    Write-Host "Restoring cache..."
    Move-Item $cacheBackup "./app/.cache"
}

# Restore custom_nodes
if (Test-Path $customNodesBackup) {
    Write-Host "Restoring custom_nodes..."
    Get-ChildItem $customNodesBackup -Directory | ForEach-Object {
        Move-Item $_.FullName "./app/custom_nodes/"
    }
    Remove-Item $customNodesBackup -Recurse -Force
}

# Overwrite requirements
Write-Host "Overwriting ./app/requirements.txt with ./requirements.txt..."
Copy-Item "./requirements.txt" "./app/requirements.txt" -Force

Write-Host "Done!"
