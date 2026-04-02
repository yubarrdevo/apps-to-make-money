#!/bin/bash
# health-check.sh - runs every 15 min via cron
# Simplified: focuses on ComfyUI + essential services only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT="${SCRIPT_DIR}/telegram-alert.sh"
LOG_DIR="${HOME}/income-services/shared/logs"
LOG="${LOG_DIR}/health-$(date +%Y%m%d).log"
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

check_service() {
  local name="$1" url="$2"
  if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
    log "✅ $name OK"
  else
    log "❌ $name DOWN"
    bash "$ALERT" "$name is DOWN - check immediately" "🚨"
  fi
}

check_container() {
  local name="$1"
  local status
  status=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null)
  if [ "$status" = "running" ]; then
    log "✅ $name running"
  else
    log "⚠️  $name status=$status — restarting"
    docker start "$name" >> "$LOG" 2>&1
    bash "$ALERT" "$name was $status — auto-restarted" "⚠️"
  fi
}

log "=== Health Check - Focused Stack ==="

# Core revenue service
check_container comfyui

# Supporting services
check_container n8n
check_container n8n-db
check_container litellm-proxy
check_container litellm-db

# HTTP endpoints
check_service "ComfyUI (PRIMARY)" "http://localhost:8188"
check_service "n8n"               "http://localhost:5678/healthz"
check_service "LiteLLM API"       "http://localhost:4000/health"
check_service "Ollama"            "http://localhost:11434/api/tags"

# GPU (only if nvidia-smi available)
if command -v nvidia-smi >/dev/null 2>&1; then
  GPU_INFO=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,temperature.gpu --format=csv,noheader 2>/dev/null || echo "unavailable")
  log "GPU: $GPU_INFO"
fi

# Disk
DISK_USE=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
log "Disk /: ${DISK_USE}% used"
if [ "$DISK_USE" -gt 85 ]; then
  bash "$ALERT" "Disk usage at ${DISK_USE}% - clean up soon" "💾"
fi

# Cloudflare tunnel
if ! pgrep -x cloudflared > /dev/null; then
  log "⚠️  cloudflared not running — restarting"
  nohup cloudflared tunnel run income-services >> /tmp/cloudflared.log 2>&1 &
  bash "$ALERT" "Cloudflare tunnel was down — restarted" "🌐"
fi

log "=== Done ==="
