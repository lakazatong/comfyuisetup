# ComfyUI Automatic Installer

## Requirements

- Git
- Docker
- NVIDIA GPU + Driver with CUDA 13 support

## Usage

To (re)clone ComfyUI, run `./init.ps1`

WARNING: This will wipe out the `./app` directory, only `./app/.cache` and `./app/custom_nodes` will be preserved

To start ComfyUI, run `docker compose up`

If you change `requirements.txt` or add a custom node to `setup.sh`, run `docker compose build`
