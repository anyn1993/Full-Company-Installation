#!/bin/bash
# ===========================================
# Start Script for Company Services
# ===========================================
# Usage: ./start.sh
#
# This script will:
# 1. Run the initialization script (if needed)
# 2. Start all Docker services
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  🚀 Starting Company Services${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  No .env file found. Running initialization script...${NC}"
    echo ""
    ./scripts/init.sh
    echo ""
    echo -e "${YELLOW}⚠️  Please edit .env with your domain and settings, then run this script again.${NC}"
    exit 0
fi

# Check if required directories exist
if [ ! -d "odoo/conf" ] || [ ! -d "nextcloud/html" ]; then
    echo -e "${YELLOW}📁 Some directories are missing. Running initialization script...${NC}"
    echo ""
    ./scripts/init.sh
    echo ""
fi

# Start all services
echo -e "${GREEN}🐳 Starting Docker services...${NC}"
echo ""

docker compose up -d

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ All services started!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Get domain from .env file
if [ -f .env ]; then
    source .env 2>/dev/null || true
fi

BASE_DOMAIN="${BASE_DOMAIN:-example.com}"

echo "Your services are available at:"
echo ""
echo -e "  ${BLUE}Dashboard:${NC}   https://${BASE_DOMAIN}"
echo -e "  ${BLUE}Odoo:${NC}        https://${ODOO_SUBDOMAIN:-odoo}.${BASE_DOMAIN}"
echo -e "  ${BLUE}OpenSign:${NC}    https://${OPENSIGN_SUBDOMAIN:-opensign}.${BASE_DOMAIN}"
echo -e "  ${BLUE}Nextcloud:${NC}   https://${NEXTCLOUD_SUBDOMAIN:-nextcloud}.${BASE_DOMAIN}"
echo -e "  ${BLUE}Mattermost:${NC}  https://${MATTERMOST_SUBDOMAIN:-mattermost}.${BASE_DOMAIN}"
echo -e "  ${BLUE}Portainer:${NC}   https://${PORTAINER_SUBDOMAIN:-portainer}.${BASE_DOMAIN}"
echo ""
echo -e "${YELLOW}Note: It may take a few minutes for SSL certificates to be issued.${NC}"
echo ""
echo "To view logs:  docker compose logs -f"
echo "To stop:       ./stop.sh"
echo ""

