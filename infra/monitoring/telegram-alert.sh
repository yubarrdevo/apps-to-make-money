#!/bin/bash
# Usage: ./telegram-alert.sh "Your message here"
# Reads TELEGRAM_TOKEN and TELEGRAM_CHAT_ID from env or shared .env file

ENV_FILE="${HOME}/income-services/shared/.gpu-scheduler.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

MESSAGE="${1:-health check}"
EMOJI="${2:-🔔}"

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "ERROR: TELEGRAM_TOKEN or TELEGRAM_CHAT_ID not set"
  exit 1
fi

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": \"${EMOJI} yuserver: ${MESSAGE}\"}" \
  > /dev/null

echo "Alert sent: $MESSAGE"
