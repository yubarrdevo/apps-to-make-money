#!/bin/bash
# download-models.sh - Download ComfyUI models to the correct directories
# Run this once before starting ComfyUI for the first time.
# Usage: bash download-models.sh [--dir /path/to/ai-content]

set -e

COMFYUI_DIR="${1:-/home/yuri/income-services/ai-content}"
CHECKPOINTS_DIR="$COMFYUI_DIR/models/checkpoints"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }

mkdir -p "$CHECKPOINTS_DIR"

download_file() {
    local url="$1"
    local dest="$2"
    local name
    name=$(basename "$dest")

    if [ -f "$dest" ]; then
        log_success "$name already exists — skipping"
        return 0
    fi

    log_info "Downloading $name ..."
    if command -v huggingface-cli &>/dev/null; then
        huggingface-cli download "$3" "$4" --local-dir "$CHECKPOINTS_DIR"
    else
        wget --show-progress -q -O "$dest.tmp" "$url" && mv "$dest.tmp" "$dest"
    fi
    log_success "$name downloaded"
}

# FLUX.1-schnell FP8 (17 GB)
download_file \
    "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors" \
    "$CHECKPOINTS_DIR/flux1-schnell-fp8.safetensors" \
    "Comfy-Org/flux1-schnell" \
    "flux1-schnell-fp8.safetensors"

# Stable Diffusion XL base 1.0 (6.5 GB)
download_file \
    "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
    "$CHECKPOINTS_DIR/sd_xl_base_1.0.safetensors" \
    "stabilityai/stable-diffusion-xl-base-1.0" \
    "sd_xl_base_1.0.safetensors"

log_success "All models are in $CHECKPOINTS_DIR"
log_info "You can now start ComfyUI: cd $COMFYUI_DIR && docker compose up -d"
