#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  local type=$1
  local message=$2
  case $type in
    info)  echo -e "${GREEN}[INFO]${NC} $message" ;;
    warn)  echo -e "${YELLOW}[WARN]${NC} $message" ;;
    error) echo -e "${RED}[ERROR]${NC} $message" ;;
  esac
}

PLUGIN_NAME=$1
PLUGIN_PORT=$2

if [[ -z "$PLUGIN_NAME" || -z "$PLUGIN_PORT" ]]; then
  log "error" "Usage: ./add-plugin.sh <plugin-name> <plugin-port>"
  exit 1
fi

# Absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_CONF_PATH="$BASE_DIR/nginx/plugins/${PLUGIN_NAME}.conf"

mkdir -p "$BASE_DIR/nginx/plugins"

log info "Creating production NGINX configuration for $PLUGIN_NAME on port $PLUGIN_PORT..."

cat <<EOF > "$PLUGIN_CONF_PATH"
# Redirects /${PLUGIN_NAME} to /${PLUGIN_NAME}/
location = /${PLUGIN_NAME} {
  return 301 /${PLUGIN_NAME}/;
}

# Transparent proxy for the Next.js plugin
location /${PLUGIN_NAME}/ {
  proxy_pass http://${PLUGIN_NAME}:${PLUGIN_PORT};
  proxy_http_version 1.1;
  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_read_timeout 240s;
  proxy_connect_timeout 60s;
}
EOF

log info "Configuration file created at $PLUGIN_CONF_PATH"

# Check if Nginx is running in Docker
if docker ps | grep -q nginx; then
  log info "Reloading Nginx configuration in Docker..."
  if [ -f "$BASE_DIR/docker-compose.yml" ]; then
    (cd "$BASE_DIR" && docker-compose exec -T nginx nginx -s reload) || \
      docker exec $(docker ps -q -f name=nginx) nginx -s reload
  else
    docker exec $(docker ps -q -f name=nginx) nginx -s reload
  fi
  log info "Nginx reloaded successfully"
else
  log warn "Nginx container not found. Start the container with 'docker-compose up -d nginx'"
fi


# Waits for NGINX to reload and the plugin to respond
PLUGIN_ROUTE="http://localhost/${PLUGIN_NAME}/"
log info "Waiting for the plugin to respond at $PLUGIN_ROUTE ..."
for i in {1..30}; do
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" "$PLUGIN_ROUTE")
  if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" ]]; then
    log info "Plugin is responding ($HTTP_CODE), proceeding with registration..."
    break
  else
    log info "Waiting for the plugin to come up... (attempt $i, status: $HTTP_CODE)"
    sleep 1
  fi
  if [ $i -eq 30 ]; then
    log warn "Timeout waiting for the plugin to respond at $PLUGIN_ROUTE"
    exit 1
  fi
done

# ------- CURL to register the plugin ---------
log info "Registering plugin in the main console via API..."

curl -s -X POST \
  http://localhost/api/plugin/manifest/register/ \
  -H "Content-Type: application/json" \
  -d "{\"host\": \"${PLUGIN_NAME}\"}"

if [ $? -eq 0 ]; then
  log info "Plugin registered successfully!"
else
  log warn "Failed to register plugin in the main console!"
fi
