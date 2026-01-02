#!/bin/bash

# =============================================================================
# Full Company Installation - Complete Restore Script
# =============================================================================
# Restores a complete backup for migration purposes
# Includes: Docker named volumes, bind-mounted directories, and databases
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -lt 1 ]; then
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Full Company Installation - Restore Script${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
    echo "Usage: $0 <backup_date> [--force]"
    echo ""
    echo "Options:"
    echo "  backup_date    The backup timestamp (e.g., 20241117_143000)"
    echo "  --force        Skip confirmation prompt"
    echo ""
    echo "Available backups:"
    echo "-------------------"
    if ls "$BACKUP_DIR"/full-backup_*.tar.gz 1>/dev/null 2>&1; then
        for backup in "$BACKUP_DIR"/full-backup_*.tar.gz; do
            filename=$(basename "$backup")
            date_part=$(echo "$filename" | sed 's/full-backup_\([0-9_]*\)\.tar\.gz/\1/')
            size=$(du -h "$backup" | cut -f1)
            echo -e "  ${YELLOW}$date_part${NC} ($size)"
        done
    else
        echo -e "  ${RED}No backups found in $BACKUP_DIR${NC}"
    fi
    echo ""
    exit 1
fi

DATE=$1
FORCE=false
if [ "$2" == "--force" ]; then
    FORCE=true
fi

BACKUP_FILE="$BACKUP_DIR/full-backup_$DATE.tar.gz"
BACKUP_NAME="full-backup_$DATE"

# Check if backup exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Full Company Installation - Restore Script${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Restoring from backup: ${YELLOW}$DATE${NC}"
echo -e "Backup file: ${YELLOW}$BACKUP_FILE${NC}"
echo ""

# Confirmation
if [ "$FORCE" != true ]; then
    echo -e "${RED}⚠️  WARNING: This will overwrite ALL existing data!${NC}"
    echo ""
    echo "This restore will:"
    echo "  - Stop all running containers"
    echo "  - Delete and recreate Docker volumes"
    echo "  - Overwrite all application data"
    echo "  - Restore all databases"
    echo ""
    read -p "Are you sure you want to continue? Type 'yes' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}[1/7] Extracting backup archive...${NC}"
echo "-----------------------------------------------"

cd "$BACKUP_DIR"
echo -n "  Extracting ${BACKUP_NAME}.tar.gz... "
tar xzf "${BACKUP_NAME}.tar.gz"
echo -e "${GREEN}✓${NC}"
cd "$PROJECT_DIR"

BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Display manifest if available
if [ -f "$BACKUP_PATH/MANIFEST.txt" ]; then
    echo ""
    echo -e "${BLUE}Backup Manifest:${NC}"
    echo "-----------------------------------------------"
    head -20 "$BACKUP_PATH/MANIFEST.txt"
    echo "..."
    echo ""
fi

echo -e "${BLUE}[2/7] Stopping all services...${NC}"
echo "-----------------------------------------------"

echo -n "  Stopping Docker Compose services... "
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
echo -e "${GREEN}✓${NC}"

# Wait for containers to fully stop
sleep 3

echo ""
echo -e "${BLUE}[3/7] Restoring configuration files...${NC}"
echo "-----------------------------------------------"

if [ -d "$BACKUP_PATH/config" ]; then
    for file in "$BACKUP_PATH/config"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo -n "  Restoring $filename... "
            cp "$file" "$PROJECT_DIR/"
            echo -e "${GREEN}✓${NC}"
        fi
    done
else
    echo -e "  ${YELLOW}⚠ No config backup found${NC}"
fi

echo ""
echo -e "${BLUE}[4/7] Restoring bind-mounted directories...${NC}"
echo "-----------------------------------------------"

if [ -d "$BACKUP_PATH/bind-mounts" ]; then
    for archive in "$BACKUP_PATH/bind-mounts"/*.tar.gz; do
        if [ -f "$archive" ]; then
            dirname=$(basename "$archive" .tar.gz)
            echo -n "  Restoring $dirname/... "
            
            # Remove existing directory
            rm -rf "$PROJECT_DIR/$dirname" 2>/dev/null || true
            
            # Extract archive
            tar xzf "$archive" -C "$PROJECT_DIR/"
            echo -e "${GREEN}✓${NC}"
        fi
    done
else
    echo -e "  ${YELLOW}⚠ No bind-mount backup found${NC}"
fi

echo ""
echo -e "${BLUE}[5/7] Restoring Docker named volumes...${NC}"
echo "-----------------------------------------------"

# Get the project name prefix for volume names
PROJECT_PREFIX=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
PROJECT_PREFIX_UNDERSCORE=$(echo "$PROJECT_PREFIX" | tr '-' '_')

if [ -d "$BACKUP_PATH/volumes" ]; then
    for archive in "$BACKUP_PATH/volumes"/*.tar.gz; do
        if [ -f "$archive" ]; then
            volname=$(basename "$archive" .tar.gz)
            FULL_VOL_NAME="${PROJECT_PREFIX_UNDERSCORE}_${volname}"
            
            echo -n "  Restoring volume: $FULL_VOL_NAME... "
            
            # Remove existing volume if it exists
            docker volume rm "$FULL_VOL_NAME" 2>/dev/null || true
            
            # Create new volume
            docker volume create "$FULL_VOL_NAME" >/dev/null
            
            # Restore data to volume
            if docker run --rm \
                -v "$FULL_VOL_NAME":/target \
                -v "$PWD/$archive":/backup.tar.gz:ro \
                alpine sh -c "cd /target && tar xzf /backup.tar.gz" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗ Failed${NC}"
            fi
        fi
    done
else
    echo -e "  ${YELLOW}⚠ No volume backup found${NC}"
fi

echo ""
echo -e "${BLUE}[6/7] Starting database containers and restoring data...${NC}"
echo "-----------------------------------------------"

# Start only database containers first
echo "  Starting database containers..."
docker compose up -d odoo-db opensign-mongo nextcloud-db mattermost-db 2>/dev/null || \
docker-compose up -d odoo-db opensign-mongo nextcloud-db mattermost-db 2>/dev/null || true

# Wait for databases to be ready
echo "  Waiting for databases to initialize (30 seconds)..."
sleep 30

# Restore Odoo PostgreSQL Database
if [ -f "$BACKUP_PATH/databases/odoo_postgres.sql.gz" ]; then
    echo -n "  Restoring Odoo database... "
    if gunzip -c "$BACKUP_PATH/databases/odoo_postgres.sql.gz" | docker exec -i odoo-db psql -U odoo -d postgres 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
fi

# Restore OpenSign MongoDB Database
if [ -f "$BACKUP_PATH/databases/opensign_mongo.archive.gz" ]; then
    echo -n "  Restoring OpenSign database... "
    if gunzip -c "$BACKUP_PATH/databases/opensign_mongo.archive.gz" | docker exec -i opensign-mongo mongorestore --archive --drop 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
fi

# Restore Nextcloud MariaDB Database
if [ -f "$BACKUP_PATH/databases/nextcloud_mariadb.sql.gz" ]; then
    echo -n "  Restoring Nextcloud database... "
    NEXTCLOUD_DB_PASSWORD="${NEXTCLOUD_DB_PASSWORD:-nextcloud}"
    if gunzip -c "$BACKUP_PATH/databases/nextcloud_mariadb.sql.gz" | docker exec -i nextcloud-db mysql -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
fi

# Restore Mattermost PostgreSQL Database
if [ -f "$BACKUP_PATH/databases/mattermost_postgres.sql.gz" ]; then
    echo -n "  Restoring Mattermost database... "
    if gunzip -c "$BACKUP_PATH/databases/mattermost_postgres.sql.gz" | docker exec -i mattermost-db psql -U mattermost -d mattermost 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[7/7] Starting all services...${NC}"
echo "-----------------------------------------------"

echo -n "  Starting all Docker Compose services... "
docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null
echo -e "${GREEN}✓${NC}"

# Cleanup extracted backup
echo ""
echo -n "Cleaning up extracted backup files... "
rm -rf "$BACKUP_PATH"
echo -e "${GREEN}✓${NC}"

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}Restore completed at: $(date)${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo "Post-restore checklist:"
echo "  1. Update .env file if domain/settings need to change"
echo "  2. Wait 2-3 minutes for all services to fully start"
echo "  3. Check service status: docker compose ps"
echo "  4. View logs if needed: docker compose logs -f"
echo ""
echo -e "${YELLOW}Note: If migrating to a new domain, you may need to:${NC}"
echo "  - Update BASE_DOMAIN in .env"
echo "  - Update NEXTCLOUD_TRUSTED_DOMAINS"
echo "  - Run Nextcloud occ commands to update trusted domains"
echo "  - Update Mattermost Site URL setting"
echo ""
