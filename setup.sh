CACHE="/root/.cache"
UV_CACHE="$CACHE/uv"
RESOLVED_REQS="$CACHE/resolved_requirements.txt"

mkdir -p "$UV_CACHE"

req_files=("/app/requirements.txt")

clone_if_not_exist() {
    local owner="$1"
    local name="$2"
    local -n req_list="$3"

    local repo_url="https://github.com/${owner}/${name}.git"
    local target_path="/app/custom_nodes/${name}"

    if [ ! -d "$target_path" ]; then
        git clone "$repo_url" "$target_path"
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

> "$RESOLVED_REQS"

for f in "${req_files[@]}"; do
    cat "$f" >> "$RESOLVED_REQS"
    echo >> "$RESOLVED_REQS"
done

echo "Installing dependencies..."
SECONDS=0
uv pip install -r "$RESOLVED_REQS" \
    --system \
    --break-system-packages \
    --exact \
    --strict \
    --torch-backend auto \
    --resolution highest \
    --prerelease disallow \
    --link-mode copy \
    --compile-bytecode \
    --cache-dir "$UV_CACHE"
duration=$SECONDS
echo "Total time: $((duration / 60)) min $((duration % 60)) sec"
