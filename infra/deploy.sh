#!/bin/bash
# deploy.sh - Automated deployment script for apps-to-make-money stack
# This script automates the complete deployment of all services
# Usage: ./deploy.sh [--full|--services|--automation|--verify]

set -e

REPO_DIR="/home/yuri/apps-to-make-money"
SERVICES_DIR="/home/yuri/income-services"
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

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to verify prerequisites
verify_prerequisites() {
    log_info "Verifying prerequisites..."

    local missing=()

    for cmd in docker docker-compose python3 curl git nvidia-smi; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        exit 1
    fi

    # Check if docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running or user doesn't have permission"
        exit 1
    fi

    # Check if NVIDIA GPU is available
    if ! nvidia-smi &> /dev/null; then
        log_error "NVIDIA GPU not detected or drivers not installed"
        exit 1
    fi

    log_success "All prerequisites verified"
}

# Function to create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."

    mkdir -p "$SERVICES_DIR"/{litellm,n8n,vllm,ai-content,bandwidth/money4band,compute,shared/{logs,backups}}

    log_success "Directory structure created"
}

# Function to setup environment files
setup_environment_files() {
    log_info "Setting up environment files..."

    # Create .gpu-scheduler.env if it doesn't exist
    if [ ! -f "$SERVICES_DIR/shared/.gpu-scheduler.env" ]; then
        cat > "$SERVICES_DIR/shared/.gpu-scheduler.env" << 'EOF'
# GPU Scheduler & Telegram Alerts Configuration
TELEGRAM_TOKEN=
TELEGRAM_CHAT_ID=
LITELLM_URL=http://localhost:4000
LITELLM_MASTER_KEY=sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6
COMFYUI_URL=http://localhost:8188
VLLM_DIR=/home/yuri/income-services/vllm
COMFYUI_DIR=/home/yuri/income-services/ai-content
EOF
        log_warn "Created .gpu-scheduler.env - PLEASE FILL IN TELEGRAM CREDENTIALS"
    else
        log_success ".gpu-scheduler.env already exists"
    fi

    # Create LiteLLM .env
    if [ ! -f "$SERVICES_DIR/litellm/.env" ]; then
        cat > "$SERVICES_DIR/litellm/.env" << EOF
LITELLM_DB_PASSWORD=9a0ac34fd8e5e7a7e8ebdf53e6dadbd9
POSTGRES_PASSWORD=9a0ac34fd8e5e7a7e8ebdf53e6dadbd9
LITELLM_MASTER_KEY=sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6
DATABASE_URL=postgresql://litellm:9a0ac34fd8e5e7a7e8ebdf53e6dadbd9@litellm-db:5432/litellm
EOF
        log_success "Created LiteLLM .env"
    fi

    # Create n8n .env
    if [ ! -f "$SERVICES_DIR/n8n/.env" ]; then
        cat > "$SERVICES_DIR/n8n/.env" << EOF
N8N_USER=admin
N8N_PASSWORD=1833d549f04774aa51b5c56b
N8N_DB_PASSWORD=dcefd4c5605b426522e3cc3316fef7c8
DB_POSTGRESDB_PASSWORD=dcefd4c5605b426522e3cc3316fef7c8
POSTGRES_PASSWORD=dcefd4c5605b426522e3cc3316fef7c8
N8N_ENCRYPTION_KEY=edc3fc948d0d27ed8aa1db04af452e43f6d585af61e6f47667236cc9fc685605
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 32)
EOF
        log_success "Created n8n .env"
    fi
}

# Function to copy service configurations
copy_service_configs() {
    log_info "Copying service configurations..."

    # Copy docker-compose files
    for service in litellm n8n vllm; do
        if [ -f "$SCRIPT_DIR/services/$service/docker-compose.yml" ]; then
            cp "$SCRIPT_DIR/services/$service/docker-compose.yml" "$SERVICES_DIR/$service/"
            log_success "Copied $service docker-compose.yml"
        fi
    done
}

# Function to create LiteLLM config
create_litellm_config() {
    log_info "Creating LiteLLM configuration..."

    cat > "$SERVICES_DIR/litellm/config.yaml" << 'EOF'
model_list:
  # CPU models via Ollama (always available)
  - model_name: gpt-3.5-turbo
    litellm_params:
      model: ollama/llama3.1:8b
      api_base: http://host.docker.internal:11434

  - model_name: fast
    litellm_params:
      model: ollama/llama3.1:8b
      api_base: http://host.docker.internal:11434

  # GPU model via vLLM (auto-started by scheduler)
  - model_name: gpt-4
    litellm_params:
      model: openai/Qwen2.5-14B-Instruct-AWQ
      api_base: http://host.docker.internal:8002/v1
      api_key: bcf27c2b3fe913e8f526af69c9f9253d4539f452dc8caec42e594d27109e4d96

  - model_name: smart
    litellm_params:
      model: openai/Qwen2.5-14B-Instruct-AWQ
      api_base: http://host.docker.internal:8002/v1
      api_key: bcf27c2b3fe913e8f526af69c9f9253d4539f452dc8caec42e594d27109e4d96

  # Embeddings
  - model_name: embed
    litellm_params:
      model: ollama/nomic-embed-text
      api_base: http://host.docker.internal:11434

litellm_settings:
  drop_params: True
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]

general_settings:
  master_key: sk-9c2d72b2b8e61d402b7316fed0276e675117cd4a1342fa572c84e7e20223c0b6
  database_url: ${DATABASE_URL}
EOF

    log_success "LiteLLM config created"
}

# Function to deploy core services
deploy_core_services() {
    log_info "Deploying core services..."

    # Deploy n8n
    log_info "Starting n8n..."
    cd "$SERVICES_DIR/n8n"
    docker compose up -d
    log_success "n8n started"

    # Deploy LiteLLM
    log_info "Starting LiteLLM..."
    cd "$SERVICES_DIR/litellm"
    docker compose up -d
    log_success "LiteLLM started"

    # vLLM is managed by GPU scheduler, don't start it here
    log_info "vLLM will be auto-started by GPU scheduler on demand"
}

# Function to install systemd services
install_systemd_services() {
    log_info "Installing systemd services..."

    # Copy systemd units
    sudo cp "$SCRIPT_DIR/gpu-scheduler/gpu-scheduler.service" /etc/systemd/system/
    sudo cp "$SCRIPT_DIR/golem/golem-provider.service" /etc/systemd/system/

    # Reload systemd
    sudo systemctl daemon-reload

    # Enable and start services
    sudo systemctl enable gpu-scheduler.service
    sudo systemctl start gpu-scheduler.service
    log_success "GPU scheduler service installed and started"

    sudo systemctl enable golem-provider.service
    sudo systemctl start golem-provider.service
    log_success "Golem provider service installed and started"
}

# Function to install cron jobs
install_cron_jobs() {
    log_info "Installing cron jobs..."

    # Backup existing crontab
    crontab -l > /tmp/crontab.backup 2>/dev/null || true

    # Create new crontab
    cat > /tmp/crontab.new << EOF
# Health check every 15 minutes
*/15 * * * * bash $REPO_DIR/infra/monitoring/health-check.sh

# Git auto-commit every hour
0 * * * * bash $REPO_DIR/infra/monitoring/git-autopush.sh

# Backup scripts (if they exist)
# 0 4 * * * ~/income-services/shared/backup-daily.sh
# 0 5 * * 0 ~/income-services/shared/backup-weekly.sh

# Clean old logs monthly
0 3 1 * * find ~/income-services/shared/logs -name '*.log' -mtime +30 -delete
EOF

    # Install new crontab
    crontab /tmp/crontab.new
    rm /tmp/crontab.new

    log_success "Cron jobs installed"
}

# Function to install Cloudflare tunnel (systemd user service)
install_cloudflare_tunnel() {
    log_info "Setting up Cloudflare tunnel systemd user service..."

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

    # Enable and start the service
    systemctl --user daemon-reload
    systemctl --user enable cloudflared.service
    systemctl --user start cloudflared.service

    log_success "Cloudflare tunnel systemd user service installed"
}

# Function to verify deployment
verify_deployment() {
    log_info "Verifying deployment..."

    local failures=0

    # Check Docker containers
    for container in n8n n8n-db litellm-proxy litellm-db; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            log_success "Container $container is running"
        else
            log_error "Container $container is NOT running"
            ((failures++))
        fi
    done

    # Check systemd services
    for service in gpu-scheduler golem-provider; do
        if systemctl is-active --quiet "$service"; then
            log_success "Service $service is active"
        else
            log_error "Service $service is NOT active"
            ((failures++))
        fi
    done

    # Check Cloudflare tunnel
    if systemctl --user is-active --quiet cloudflared; then
        log_success "Cloudflare tunnel is active"
    else
        log_error "Cloudflare tunnel is NOT active"
        ((failures++))
    fi

    # Check HTTP endpoints
    sleep 5  # Give services time to fully start

    if curl -sf http://localhost:4000/health &> /dev/null; then
        log_success "LiteLLM API is responding"
    else
        log_warn "LiteLLM API is not responding yet (may need more time)"
    fi

    if curl -sf http://localhost:5678/healthz &> /dev/null; then
        log_success "n8n is responding"
    else
        log_warn "n8n is not responding yet (may need more time)"
    fi

    if [ $failures -eq 0 ]; then
        log_success "All critical services are running!"
        return 0
    else
        log_error "$failures service(s) failed to start"
        return 1
    fi
}

# Function to display post-deployment instructions
show_post_deploy_instructions() {
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                     🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

NEXT STEPS TO COMPLETE SETUP:

1. Configure Telegram Bot (5 minutes)
   - Open Telegram → search @BotFather
   - Create bot: /newbot
   - Copy token and chat_id to: ~/income-services/shared/.gpu-scheduler.env
   - Get chat_id: search @userinfobot → /start
   - Test: bash ~/apps-to-make-money/infra/monitoring/telegram-alert.sh "test"

2. Import n8n Workflows
   - Open: https://n8n.atividata.com.br
   - Login: admin / 1833d549f04774aa51b5c56b
   - Import:
     * ~/apps-to-make-money/infra/n8n-workflows/daily-video-generator.json
     * ~/apps-to-make-money/infra/n8n-workflows/stripe-client-provisioning.json
   - Configure n8n variables (Settings → Variables):
     * LITELLM_MASTER_KEY
     * TELEGRAM_CHAT_ID
     * RESEND_API_KEY (get from resend.com)

3. Setup Stripe (for payment processing)
   - Create account at stripe.com
   - Create products: R$97, R$297, R$597/month
   - Add webhook: https://n8n.atividata.com.br/webhook/stripe-payment
   - Events: checkout.session.completed, invoice.payment_succeeded
   - Add webhook secret to n8n credentials

4. Optional: Setup Additional Services
   - ComfyUI: cd ~/income-services/ai-content && docker compose up -d
   - money4band: Fill credentials in ~/income-services/bandwidth/money4band/.env

MONITORING & LOGS:

- Check service status: docker ps
- GPU status: nvidia-smi
- GPU scheduler logs: journalctl -u gpu-scheduler -f
- Golem logs: journalctl -u golem-provider -f
- Cloudflare tunnel: systemctl --user status cloudflared
- Health logs: tail -f ~/income-services/shared/logs/health-$(date +%Y%m%d).log

PUBLIC ENDPOINTS:

- LiteLLM API: https://llm.ativadata.com
- n8n: https://n8n.atividata.com.br

For detailed documentation, see:
- GUIA-COMPLETO.md
- PARA-LEIGOS.md

EOF
}

# Main deployment flow
main() {
    local mode="${1:-full}"

    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║              apps-to-make-money Automated Deployment Script                  ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    case "$mode" in
        --full)
            verify_prerequisites
            create_directory_structure
            setup_environment_files
            copy_service_configs
            create_litellm_config
            deploy_core_services
            install_systemd_services
            install_cron_jobs
            install_cloudflare_tunnel
            verify_deployment
            show_post_deploy_instructions
            ;;
        --services)
            verify_prerequisites
            deploy_core_services
            verify_deployment
            ;;
        --automation)
            install_systemd_services
            install_cron_jobs
            install_cloudflare_tunnel
            ;;
        --verify)
            verify_deployment
            ;;
        *)
            log_error "Usage: $0 [--full|--services|--automation|--verify]"
            log_info "  --full       : Complete deployment (default)"
            log_info "  --services   : Deploy only Docker services"
            log_info "  --automation : Install only automation (systemd, cron, tunnel)"
            log_info "  --verify     : Verify existing deployment"
            exit 1
            ;;
    esac
}

main "$@"
