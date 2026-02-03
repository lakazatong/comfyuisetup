RESOLVED_REQ="/app/.cache/resolved-requirements.txt"
WHEEL_CACHE="/app/.cache/wheels"
mkdir -p "$WHEEL_CACHE"

# Start with the base requirements
req_files=("/requirements.txt")
cloned_any=0   # flag to track if at least one repo was cloned

clone_if_not_exist() {
    local owner="$1"
    local name="$2"
    local -n req_list="$3"

    local repo_url="https://github.com/${owner}/${name}.git"
    local target_path="/app/custom_nodes/${name}"

    if [ ! -d "$target_path" ]; then
        git clone "$repo_url" "$target_path"
        cloned_any=1       # set flag if a repo was cloned
    fi

    # Check if requirements.txt exists and add to list
    local req_file="${target_path}/requirements.txt"
    if [ -f "$req_file" ]; then
        req_list+=("$req_file")
    fi
}

# List of custom node repos
custom_nodes=(
    "Comfy-Org ComfyUI-Manager"
    "cubiq ComfyUI_essentials"
    "crystian ComfyUI-Crystools"
    "ltdrdata ComfyUI-Impact-Pack"
    "ltdrdata ComfyUI-Impact-Subpack"
    "rgthree rgthree-comfy"
    "kijai ComfyUI-KJNodes"
    "giriss comfy-image-saver"
    "jags111 efficiency-nodes-comfyui"
)

for entry in "${custom_nodes[@]}"; do
    read -r owner name <<< "$entry"
    clone_if_not_exist "$owner" "$name" req_files
done

resolved_deps=0
# Resolve packages if resolved-requirements.txt is missing or at least one repo was cloned
if [ ! -f "$RESOLVED_REQ" ] || [ "$cloned_any" -eq 1 ]; then
    echo "Resolving dependencies..."
    pip-compile "${req_files[@]}" \
        --output-file "$RESOLVED_REQ" \
        --resolver backtracking \
        --newline crlf \
        --index-url https://download.pytorch.org/whl/cu130 \
        --extra-index-url https://pypi.org/simple
    resolved_deps=1
fi

# Download packages if wheels folder is missing or at least one repo was cloned
if [ ! -d "$WHEEL_CACHE" ] || [ "$cloned_any" -eq 1 ] || [ "$resolved_deps" -eq 1 ]; then
    echo "Downloading wheels..."
    pip wheel -r "$RESOLVED_REQ" -w "$WHEEL_CACHE" \
        --index-url https://download.pytorch.org/whl/cu130 \
        --extra-index-url https://pypi.org/simple
fi

echo "Installing dependencies..."
pip install --root-user-action=ignore --no-index --find-links "$WHEEL_CACHE" -r "$RESOLVED_REQ"
