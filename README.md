# ComfyUI Setup

## Requirements

- Windows
- Git
- Docker
- NVIDIA GPU

Ensure you have your GPU's latest driver installed, see https://www.nvidia.com/en-us/geforce/drivers

## Getting started

`.\init.ps1`
`docker compose up`

## Usage

To (re)clone ComfyUI, run `.\init.ps1`

WARNING: This will wipe out the `./app` directory, only those will be preserved by default:

- ./app/models
- ./app/input
- ./app/output
- ./app/user/default/workflows

You can easily modify what's being preserved in `init.ps1`

To start ComfyUI, run `docker compose up`

If you modify `entrypoint.sh` or `setup.sh`, run `docker compose build` while the container is stopped then `docker compose up`

Don't modify `requirements.txt` directly, run `init.ps1` at least once and modify `./app/requirements.txt` instead, then run `docker compose up`

## Symlinks

To see how to setup symlinks, see docker-compose.yml

This allows to have models and more somewhere else, or on another disk entirely
