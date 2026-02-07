RESOLVED_REQ="/app/.cache/resolved-requirements.txt"
WHEEL_CACHE="/app/.cache/wheels"
mkdir -p "$WHEEL_CACHE"

req_files=("/app/requirements.txt")
cloned_any=0

clone_if_not_exist() {
    local owner="$1"
    local name="$2"
    local -n req_list="$3"

    local repo_url="https://github.com/${owner}/${name}.git"
    local target_path="/app/custom_nodes/${name}"

    if [ ! -d "$target_path" ]; then
        git clone "$repo_url" "$target_path"
        cloned_any=1
    fi

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

total_duration=0

resolved_deps=0
# Resolve packages if RESOLVED_REQ is missing or at least one repo was cloned
if [ ! -f "$RESOLVED_REQ" ] || [ "$cloned_any" -eq 1 ]; then
    echo "Resolving dependencies..."
    SECONDS=0
    pip-compile "${req_files[@]}" \
        --output-file "$RESOLVED_REQ" \
        --resolver backtracking \
        --newline crlf \
        --no-strip-extras \
        --index-url https://download.pytorch.org/whl/cu130 \
        --extra-index-url https://pypi.org/simple
    duration=$SECONDS
    total_duration=$((total_duration + duration))
    echo "Resolving time: $((duration / 60)) min $((duration % 60)) sec"
    resolved_deps=1
fi

# Download packages if wheels folder is missing or dependencies were just resolved
if [ ! -d "$WHEEL_CACHE" ] || [ "$resolved_deps" -eq 1 ]; then
    echo "Downloading wheels..."
    SECONDS=0
    pip wheel \
        -r "$RESOLVED_REQ" \
        -w "$WHEEL_CACHE" \
        --index-url https://download.pytorch.org/whl/cu130 \
        --extra-index-url https://pypi.org/simple
    duration=$SECONDS
    total_duration=$((total_duration + duration))
    echo "Downloading time: $((duration / 60)) min $((duration % 60)) sec"
fi

echo "Installing dependencies..."
SECONDS=0
pip install \
    --root-user-action=ignore \
    --no-index \
    --find-links "$WHEEL_CACHE" \
    "$WHEEL_CACHE"/*.whl
duration=$SECONDS
total_duration=$((total_duration+duration))
echo "Installing time: $((duration / 60)) min $((duration % 60)) sec"

echo "Total time: $((total_duration / 60)) min $((total_duration % 60)) sec"
