#!/bin/bash
# deploy.sh - Simplified deployment for ComfyUI-focused stack
# Usage: ./deploy.sh [comfyui|n8n|litellm|all|status]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="${SCRIPT_DIR}/services"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

check_deps() {
  log "Checking dependencies..."
  command -v docker >/dev/null 2>&1 || error "Docker not installed"
  command -v docker compose >/dev/null 2>&1 || error "Docker Compose not installed"

  if ! docker ps >/dev/null 2>&1; then
    error "Docker daemon not running or insufficient permissions"
  fi

  success "Dependencies OK"
}

deploy_comfyui() {
  log "Deploying ComfyUI (PRIMARY revenue service)..."

  cd "$SERVICES_DIR/comfyui"

  # Check for models
  if [ ! -d "models/checkpoints" ]; then
    mkdir -p models/checkpoints
    warn "No models found. Download FLUX model:"
    echo "  cd $SERVICES_DIR/comfyui/models/checkpoints"
    echo "  wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
  fi

  # Check GPU
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    warn "nvidia-smi not found - GPU may not be available"
  else
    nvidia-smi --query-gpu=name --format=csv,noheader
  fi

  docker compose up -d
  success "ComfyUI deployed → http://localhost:8188"
}

deploy_n8n() {
  log "Deploying n8n (automation platform)..."

  cd "$SERVICES_DIR/n8n"

  if [ ! -f ".env" ]; then
    log "Creating .env with generated secrets..."
    cp .env.example .env
    local db_pass enc_key admin_pass
    db_pass=$(openssl rand -hex 16)
    enc_key=$(openssl rand -hex 32)
    admin_pass=$(openssl rand -hex 12)
    sed -i "s/^N8N_DB_PASSWORD=CHANGE_ME/N8N_DB_PASSWORD=${db_pass}/" .env
    sed -i "s/^N8N_ENCRYPTION_KEY=CHANGE_ME/N8N_ENCRYPTION_KEY=${enc_key}/" .env
    sed -i "s/^N8N_PASSWORD=CHANGE_ME/N8N_PASSWORD=${admin_pass}/" .env
    success "Generated .env with secure credentials"
    echo "  Credentials saved in: $(pwd)/.env"
  fi

  docker compose up -d
  success "n8n deployed → http://localhost:5678"
}

deploy_litellm() {
  log "Deploying LiteLLM (optional LLM API gateway)..."

  cd "$SERVICES_DIR/litellm"

  if [ ! -f ".env" ]; then
    log "Creating .env with generated secrets..."
    cp .env.example .env
    local db_pass master_key
    db_pass=$(openssl rand -hex 16)
    master_key="sk-$(openssl rand -hex 32)"
    sed -i "s/^LITELLM_DB_PASSWORD=CHANGE_ME/LITELLM_DB_PASSWORD=${db_pass}/" .env
    sed -i "s/^LITELLM_MASTER_KEY=CHANGE_ME/LITELLM_MASTER_KEY=${master_key}/" .env
    success "Generated .env with secure credentials"
    echo "  Credentials saved in: $(pwd)/.env"
  fi

  # Check Ollama
  if command -v systemctl >/dev/null 2>&1 && ! systemctl is-active --quiet ollama 2>/dev/null; then
    warn "Ollama service not running. LiteLLM needs Ollama for model inference."
    warn "Start with: sudo systemctl start ollama"
    warn "Deploying LiteLLM anyway — it will retry connecting to Ollama."
  fi

  docker compose up -d
  success "LiteLLM deployed → http://localhost:4000"
}

show_status() {
  log "Service Status:"
  echo ""

  echo "🎨 ComfyUI (PRIMARY):"
  docker ps --filter "name=comfyui" --format "  {{.Status}}" 2>/dev/null || echo "  Not running"

  echo ""
  echo "⚙️  n8n (automation):"
  docker ps --filter "name=n8n" --format "  {{.Status}}" 2>/dev/null || echo "  Not running"

  echo ""
  echo "🤖 LiteLLM (LLM API):"
  docker ps --filter "name=litellm" --format "  {{.Status}}" 2>/dev/null || echo "  Not running"

  echo ""
  echo "🖥️  GPU:"
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=utilization.gpu,memory.used,temperature.gpu --format=csv,noheader,nounits | \
      awk '{printf "  Utilization: %s%%, Memory: %s MB, Temp: %s°C\n", $1, $2, $3}'
  else
    echo "  nvidia-smi not available"
  fi

  echo ""
  echo "📊 Disk Usage:"
  df -h / | awk 'NR==2{printf "  Root: %s used of %s (%s)\n", $3, $2, $5}'
}

main() {
  case "${1:-}" in
    comfyui)
      check_deps
      deploy_comfyui
      ;;
    n8n)
      check_deps
      deploy_n8n
      ;;
    litellm)
      check_deps
      deploy_litellm
      ;;
    all)
      check_deps
      deploy_comfyui
      deploy_n8n
      deploy_litellm
      success "All services deployed!"
      echo ""
      show_status
      ;;
    status)
      show_status
      ;;
    *)
      echo "Usage: $0 {comfyui|n8n|litellm|all|status}"
      echo ""
      echo "Commands:"
      echo "  comfyui  - Deploy ComfyUI (PRIMARY revenue service)"
      echo "  n8n      - Deploy n8n automation platform"
      echo "  litellm  - Deploy LiteLLM LLM API gateway"
      echo "  all      - Deploy all services"
      echo "  status   - Show status of all services"
      echo ""
      echo "Example:"
      echo "  $0 comfyui     # Start with the main service"
      echo "  $0 status      # Check what's running"
      exit 1
      ;;
  esac
}

main "$@"
