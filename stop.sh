#!/bin/bash
# ===========================================
# Stop Script for Company Services
# ===========================================
# Usage: ./stop.sh
#
# This script will stop all Docker services gracefully.
# Data is preserved and services can be restarted with ./start.sh
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  🛑 Stopping Company Services${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running. Nothing to stop.${NC}"
    exit 0
fi

# Stop all services
echo -e "${YELLOW}🐳 Stopping Docker services...${NC}"
echo ""

docker compose down

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ All services stopped!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Your data has been preserved."
echo ""
echo "To start again:  ./start.sh"
echo "To remove data:  docker compose down -v  (⚠️  DESTRUCTIVE)"
echo ""

