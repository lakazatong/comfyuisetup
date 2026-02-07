# Define backup items
# Format: @{ Path = "./app/something"; Type = "file"|"folder"|"files"|"folders" }
# file: single file
# folder: the whole folder
# files: all files in the folder
# folders: all folders in the folder
$backupList = @(
    @{ Path = "./app/models"; Type = "folder" } # backup models
    @{ Path = "./app/input"; Type = "folder" } # backup input
    @{ Path = "./app/output"; Type = "folder" } # backup output
    @{ Path = "./app/user/default/workflows"; Type = "folder" } # backup workflows
    # @{ Path = "./app/custom_nodes"; Type = "folders" } # backup custom nodes
)

# Backup
foreach ($item in $backupList) {
    $source = $item.Path
    $mode = $item.Type
    $backup = "./$(Split-Path $source -Leaf)-backup"

    if (Test-Path $source) {
        Write-Host "Backing up $source to $backup..."
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
        if ($mode -in @("files","folders")) { New-Item -ItemType Directory -Path $backup | Out-Null }

        switch ($mode) {
            "file" { Copy-Item $source $backup }
            "folder" { Move-Item $source $backup }
            "files" { Get-ChildItem $source -File | ForEach-Object { Move-Item $_.FullName $backup } }
            "folders" { Get-ChildItem $source -Directory | ForEach-Object { Move-Item $_.FullName $backup } }
        }
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

# Restore backups
foreach ($item in $backupList) {
    $source = $item.Path
    $mode = $item.Type
    $backup = "./$(Split-Path $source -Leaf)-backup"

    if (Test-Path $backup) {
        Write-Host "Restoring $backup to $source..."
        $parent = Split-Path $source -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        switch ($mode) {
            "file" { Move-Item $backup $source -Force }
            "folder" { Move-Item $backup $source -Force }
            "files" {
                Get-ChildItem $backup -File | ForEach-Object { Move-Item $_.FullName $source }
            }
            "folders" {
                Get-ChildItem $backup -Directory | ForEach-Object { Move-Item $_.FullName $source }
            }
        }
        if ($mode -in @("files","folders")) { Remove-Item $backup -Recurse -Force }
    }
}

# Overwrite requirements
Write-Host "Overwriting ./app/requirements.txt with ./requirements.txt..."
Copy-Item "./requirements.txt" "./app/requirements.txt" -Force

Write-Host "Done!"
