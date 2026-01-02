#!/bin/bash

# =============================================================================
# Full Company Installation - Complete Backup Script
# =============================================================================
# Creates a complete backup of all data for migration purposes
# Includes: Docker named volumes, bind-mounted directories, and databases
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="full-backup_$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Full Company Installation - Backup Script${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Backup started at: $(date)"
echo -e "Backup location: ${YELLOW}$BACKUP_PATH${NC}"
echo ""

# Create backup directory structure
mkdir -p "$BACKUP_PATH/volumes"
mkdir -p "$BACKUP_PATH/databases"
mkdir -p "$BACKUP_PATH/bind-mounts"
mkdir -p "$BACKUP_PATH/config"

# Get the project name prefix for volume names
PROJECT_PREFIX=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
# Docker Compose typically uses underscores
PROJECT_PREFIX_UNDERSCORE=$(echo "$PROJECT_PREFIX" | tr '-' '_')

echo -e "${BLUE}[1/6] Backing up Docker named volumes...${NC}"
echo "-----------------------------------------------"

# List of named volumes to backup (from docker-compose.yml)
NAMED_VOLUMES=(
    "caddy_data"
    "caddy_config"
    "mattermost_config"
    "mattermost_data"
    "mattermost_logs"
    "mattermost_plugins"
    "mattermost_client_plugins"
    "portainer_data"
)

for vol in "${NAMED_VOLUMES[@]}"; do
    # Try both naming conventions (with and without project prefix)
    FULL_VOL_NAME="${PROJECT_PREFIX_UNDERSCORE}_${vol}"
    
    # Check if volume exists with project prefix
    if docker volume inspect "$FULL_VOL_NAME" &>/dev/null; then
        VOL_TO_BACKUP="$FULL_VOL_NAME"
    elif docker volume inspect "$vol" &>/dev/null; then
        VOL_TO_BACKUP="$vol"
    else
        echo -e "  ${YELLOW}⚠ Volume '$vol' not found, skipping${NC}"
        continue
    fi
    
    echo -n "  Backing up volume: $VOL_TO_BACKUP... "
    if docker run --rm \
        -v "$VOL_TO_BACKUP":/source:ro \
        -v "$PWD/$BACKUP_PATH/volumes":/backup \
        alpine tar czf "/backup/${vol}.tar.gz" -C /source . 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
done

echo ""
echo -e "${BLUE}[2/6] Backing up databases...${NC}"
echo "-----------------------------------------------"

# Backup Odoo PostgreSQL Database
echo -n "  Backing up Odoo database (PostgreSQL)... "
if docker exec odoo-db pg_dump -U odoo -d postgres 2>/dev/null | gzip > "$BACKUP_PATH/databases/odoo_postgres.sql.gz"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed (container may not be running)${NC}"
fi

# Backup OpenSign MongoDB Database
echo -n "  Backing up OpenSign database (MongoDB)... "
if docker exec opensign-mongo mongodump --quiet --archive 2>/dev/null | gzip > "$BACKUP_PATH/databases/opensign_mongo.archive.gz"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed (container may not be running)${NC}"
fi

# Backup Nextcloud MariaDB Database
echo -n "  Backing up Nextcloud database (MariaDB)... "
NEXTCLOUD_DB_PASSWORD="${NEXTCLOUD_DB_PASSWORD:-nextcloud}"
if docker exec nextcloud-db mysqldump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud 2>/dev/null | gzip > "$BACKUP_PATH/databases/nextcloud_mariadb.sql.gz"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed (container may not be running)${NC}"
fi

# Backup Mattermost PostgreSQL Database
echo -n "  Backing up Mattermost database (PostgreSQL)... "
if docker exec mattermost-db pg_dump -U mattermost -d mattermost 2>/dev/null | gzip > "$BACKUP_PATH/databases/mattermost_postgres.sql.gz"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed (container may not be running)${NC}"
fi

echo ""
echo -e "${BLUE}[3/6] Backing up bind-mounted directories...${NC}"
echo "-----------------------------------------------"

# Backup bind-mounted directories
BIND_MOUNT_DIRS=(
    "odoo"
    "nextcloud"
    "open-sign-forms"
    "mattermost"
    "caddy"
)

for dir in "${BIND_MOUNT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -n "  Backing up $dir/... "
        if tar czf "$BACKUP_PATH/bind-mounts/${dir}.tar.gz" "$dir" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠ Partial (some files may be locked)${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ Directory '$dir' not found, skipping${NC}"
    fi
done

echo ""
echo -e "${BLUE}[4/6] Backing up configuration files...${NC}"
echo "-----------------------------------------------"

# Backup configuration files
CONFIG_FILES=(
    ".env"
    "docker-compose.yml"
    "start.sh"
    "stop.sh"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -n "  Backing up $file... "
        cp "$file" "$BACKUP_PATH/config/"
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "  ${YELLOW}⚠ File '$file' not found, skipping${NC}"
    fi
done

echo ""
echo -e "${BLUE}[5/6] Creating backup manifest...${NC}"
echo "-----------------------------------------------"

# Create manifest file with backup information
cat > "$BACKUP_PATH/MANIFEST.txt" << EOF
Full Company Installation Backup
================================
Created: $(date)
Hostname: $(hostname)
Docker Version: $(docker --version 2>/dev/null || echo "N/A")

Contents:
---------
volumes/        - Docker named volumes (Caddy, Mattermost, Portainer)
databases/      - Database dumps (PostgreSQL, MongoDB, MariaDB)
bind-mounts/    - Bind-mounted directories (Odoo, Nextcloud, OpenSign, etc.)
config/         - Configuration files (.env, docker-compose.yml)

Volumes Backed Up:
$(ls -la "$BACKUP_PATH/volumes/" 2>/dev/null | tail -n +4 || echo "  None")

Databases Backed Up:
$(ls -la "$BACKUP_PATH/databases/" 2>/dev/null | tail -n +4 || echo "  None")

Bind Mounts Backed Up:
$(ls -la "$BACKUP_PATH/bind-mounts/" 2>/dev/null | tail -n +4 || echo "  None")

Config Files Backed Up:
$(ls -la "$BACKUP_PATH/config/" 2>/dev/null | tail -n +4 || echo "  None")

Restore Instructions:
--------------------
1. Copy this backup to the new server
2. Extract if compressed: tar xzf ${BACKUP_NAME}.tar.gz
3. Run: ./scripts/restore.sh $DATE
4. Update .env file with new domain/settings if needed
5. Start services: ./start.sh

EOF
echo -e "  Manifest created ${GREEN}✓${NC}"

echo ""
echo -e "${BLUE}[6/6] Creating final archive...${NC}"
echo "-----------------------------------------------"

# Create a single compressed archive of everything
echo -n "  Creating ${BACKUP_NAME}.tar.gz... "
cd "$BACKUP_DIR"
if tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"; then
    echo -e "${GREEN}✓${NC}"
    
    # Remove the uncompressed backup directory
    rm -rf "$BACKUP_NAME"
    
    # Calculate final size
    FINAL_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    echo -e "  Final backup size: ${YELLOW}$FINAL_SIZE${NC}"
else
    echo -e "${RED}✗ Failed to create archive${NC}"
fi

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}Backup completed at: $(date)${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Backup file: ${YELLOW}$BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"
echo ""

# Clean up old backups (keep last 7 days) if requested
if [ "$1" == "--cleanup" ]; then
    echo -e "${BLUE}Cleaning up old backups (keeping last 7 days)...${NC}"
    find "$BACKUP_DIR" -name "full-backup_*.tar.gz" -mtime +7 -delete
    echo -e "${GREEN}✓ Cleanup completed${NC}"
fi

echo "To restore on another server, copy the backup file and run:"
echo -e "  ${YELLOW}./scripts/restore.sh $DATE${NC}"
echo ""
