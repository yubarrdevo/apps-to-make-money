#!/bin/bash
# troubleshoot.sh - Quick troubleshooting and diagnostics
# Usage: ./troubleshoot.sh [service|all]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    Troubleshooting & Diagnostics                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Docker containers
log_info "Docker Containers Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
echo ""

# Check critical services
log_info "Checking Critical Services:"
for service in n8n litellm-proxy n8n-db litellm-db; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        log_success "$service is running"
    else
        log_error "$service is NOT running"
        echo "   To start: cd ~/income-services/$(echo $service | cut -d- -f1) && docker compose up -d"
    fi
done
echo ""

# Systemd services
log_info "Systemd Services Status:"
for service in gpu-scheduler golem-provider; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log_success "$service is active"
    else
        log_warn "$service is NOT active or not installed"
        echo "   To start: sudo systemctl start $service"
        echo "   To install: bash ~/apps-to-make-money/infra/install-automation.sh"
    fi
done

# Cloudflare tunnel (user service)
if systemctl --user is-active --quiet cloudflared 2>/dev/null; then
    log_success "cloudflared (user service) is active"
else
    log_warn "cloudflared is NOT active"
    echo "   To start: systemctl --user start cloudflared"
    echo "   To install: bash ~/apps-to-make-money/infra/install-automation.sh"
fi
echo ""

# GPU Status
log_info "GPU Status:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader | \
        awk -F',' '{printf "   GPU %s: %s | Util: %s | Mem: %s/%s | Temp: %s\n", $1, $2, $3, $4, $5, $6}'
else
    log_error "nvidia-smi not found"
fi
echo ""

# HTTP Endpoints
log_info "HTTP Endpoints Status:"
check_http() {
    local name="$1" url="$2"
    if curl -sf --max-time 3 "$url" &> /dev/null; then
        log_success "$name: $url"
    else
        log_error "$name: $url (NOT responding)"
    fi
}

check_http "LiteLLM API" "http://localhost:4000/health"
check_http "n8n" "http://localhost:5678/healthz"
check_http "Ollama" "http://localhost:11434/api/tags"
check_http "MoneyPrinter" "http://localhost:8080/api/models"
echo ""

# Disk Usage
log_info "Disk Usage:"
df -h / | awk 'NR==1{print "   " $0} NR==2{print "   " $0}'
echo ""

# Memory Usage
log_info "Memory Usage:"
free -h | awk 'NR==1{print "   " $0} NR==2{print "   " $0}'
echo ""

# Recent Logs
log_info "Recent Errors in Logs:"
if [ -d ~/income-services/shared/logs ]; then
    log_file=~/income-services/shared/logs/health-$(date +%Y%m%d).log
    if [ -f "$log_file" ]; then
        grep -E "(❌|⚠️|ERROR)" "$log_file" 2>/dev/null | tail -5 || echo "   No recent errors"
    else
        log_warn "No health log for today"
    fi
else
    log_warn "Logs directory not found"
fi
echo ""

# Quick Actions
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                             Quick Actions                                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Restart all Docker services:"
echo "   cd ~/income-services/n8n && docker compose restart"
echo "   cd ~/income-services/litellm && docker compose restart"
echo ""
echo "View logs:"
echo "   docker logs litellm-proxy -f"
echo "   docker logs n8n -f"
echo "   journalctl -u gpu-scheduler -f"
echo "   tail -f ~/income-services/shared/logs/health-\$(date +%Y%m%d).log"
echo ""
echo "Test Telegram alerts:"
echo "   bash ~/apps-to-make-money/infra/monitoring/telegram-alert.sh \"test\""
echo ""
echo "Check GPU allocation:"
echo "   journalctl -u gpu-scheduler -n 50"
echo ""
echo "Redeploy everything:"
echo "   cd ~/apps-to-make-money && bash infra/deploy.sh --full"
echo ""
