#!/usr/bin/env bash
set -e

mkdir -p "$YOLO_CONFIG_DIR"
chmod 700 "$YOLO_CONFIG_DIR"

/setup.sh
python /app/main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --base-directory /app \
    --use-sage-attention \
    --mmap-torch-files
