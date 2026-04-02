#!/bin/bash
# install-automation.sh - Install systemd services and cron jobs
# This script installs all automation components (systemd services, cron jobs)

set -e

REPO_DIR="/home/yuri/apps-to-make-money"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Check if running as correct user
if [ "$USER" != "yuri" ]; then
    log_error "This script must be run as user 'yuri'"
    exit 1
fi

install_systemd_services() {
    log_info "Installing systemd services..."

    # Install system services (require sudo)
    sudo cp "$SCRIPT_DIR/gpu-scheduler/gpu-scheduler.service" /etc/systemd/system/
    sudo cp "$SCRIPT_DIR/golem/golem-provider.service" /etc/systemd/system/

    # Reload systemd
    sudo systemctl daemon-reload

    # Enable and start GPU scheduler
    sudo systemctl enable gpu-scheduler.service
    if sudo systemctl is-active --quiet gpu-scheduler; then
        log_info "Restarting gpu-scheduler service..."
        sudo systemctl restart gpu-scheduler.service
    else
        log_info "Starting gpu-scheduler service..."
        sudo systemctl start gpu-scheduler.service
    fi
    log_success "GPU scheduler service installed and started"

    # Enable and start Golem provider
    sudo systemctl enable golem-provider.service
    if sudo systemctl is-active --quiet golem-provider; then
        log_info "Restarting golem-provider service..."
        sudo systemctl restart golem-provider.service
    else
        log_info "Starting golem-provider service..."
        sudo systemctl start golem-provider.service
    fi
    log_success "Golem provider service installed and started"

    # Install Cloudflare tunnel as user service
    log_info "Installing Cloudflare tunnel systemd user service..."
    mkdir -p ~/.config/systemd/user

    cat > ~/.config/systemd/user/cloudflared.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared tunnel run income-services
Restart=always
RestartSec=10
StandardOutput=append:/tmp/cloudflared.log
StandardError=append:/tmp/cloudflared.log

[Install]
WantedBy=default.target
EOF

    # Reload user systemd
    systemctl --user daemon-reload

    # Enable and start cloudflared
    systemctl --user enable cloudflared.service
    if systemctl --user is-active --quiet cloudflared; then
        log_info "Restarting cloudflared service..."
        systemctl --user restart cloudflared.service
    else
        log_info "Starting cloudflared service..."
        systemctl --user start cloudflared.service
    fi
    log_success "Cloudflare tunnel systemd user service installed and started"
}

install_cron_jobs() {
    log_info "Installing cron jobs..."

    # Backup existing crontab
    if crontab -l > /dev/null 2>&1; then
        crontab -l > /tmp/crontab.backup
        log_info "Backed up existing crontab to /tmp/crontab.backup"
    fi

    # Get existing crontab or create empty
    crontab -l > /tmp/crontab.current 2>/dev/null || echo "" > /tmp/crontab.current

    # Add our jobs if they don't exist
    add_cron_job() {
        local job="$1"
        if ! grep -qF "$job" /tmp/crontab.current; then
            echo "$job" >> /tmp/crontab.current
            log_success "Added cron job: $job"
        else
            log_info "Cron job already exists: $job"
        fi
    }

    add_cron_job "*/15 * * * * bash $REPO_DIR/infra/monitoring/health-check.sh"
    add_cron_job "0 * * * * bash $REPO_DIR/infra/monitoring/git-autopush.sh"
    add_cron_job "0 3 1 * * find ~/income-services/shared/logs -name '*.log' -mtime +30 -delete"

    # Install the updated crontab
    crontab /tmp/crontab.current
    rm /tmp/crontab.current

    log_success "Cron jobs installed"
}

show_status() {
    log_info "Checking service status..."
    echo ""

    echo "System Services:"
    sudo systemctl status gpu-scheduler --no-pager || true
    echo ""
    sudo systemctl status golem-provider --no-pager || true
    echo ""

    echo "User Services:"
    systemctl --user status cloudflared --no-pager || true
    echo ""

    echo "Cron Jobs:"
    crontab -l | grep -E "(health-check|git-autopush)" || log_warn "No automation cron jobs found"
    echo ""
}

main() {
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║               Installing Automation (systemd + cron)                         ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    local action="${1:-all}"

    case "$action" in
        all)
            install_systemd_services
            install_cron_jobs
            show_status
            ;;
        systemd)
            install_systemd_services
            show_status
            ;;
        cron)
            install_cron_jobs
            crontab -l
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Usage: $0 [all|systemd|cron|status]"
            exit 1
            ;;
    esac

    log_success "Automation installation complete!"
}

main "$@"
