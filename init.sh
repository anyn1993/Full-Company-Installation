#!/bin/bash
# Initialization Script for Company Services
# Run this script ONCE before starting docker-compose for the first time
# Usage: ./scripts/init.sh

set -e

echo "🚀 Initializing Company Services..."
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "📁 Working directory: $PROJECT_DIR"
echo ""

# ============================================
# Create all required directories
# ============================================
echo "📂 Creating required directories..."

# Function to ensure directory exists and is writable
ensure_dir() {
    local dir=$1
    if [ -d "$dir" ]; then
        # Check if we can write to it
        if ! touch "$dir/.write_test" 2>/dev/null; then
            echo "   ⚠️  $dir exists but is not writable (owned by root from Docker)"
            echo "      Run: sudo rm -rf $dir && mkdir -p $dir"
            return 1
        fi
        rm -f "$dir/.write_test"
    else
        mkdir -p "$dir"
    fi
    return 0
}

# Odoo directories
ensure_dir odoo/conf || NEEDS_SUDO=1
ensure_dir odoo/web_data || NEEDS_SUDO=1
ensure_dir odoo/extra-addons || NEEDS_SUDO=1
ensure_dir odoo/db_data || NEEDS_SUDO=1
mkdir -p odoo/addons/{web,reporting-engine,manufacture,purchase-workflow,icons} 2>/dev/null || true

# OpenSign directories
mkdir -p open-sign-forms/mongodb-data open-sign-forms/opensign-files

# Nextcloud directories
mkdir -p nextcloud/{html,data,config,custom_apps,db_data}

# Mattermost database directory (data uses named volumes for permission compatibility)
mkdir -p mattermost/db_data

# Portainer directories
mkdir -p portainer/data

# Caddy directories
mkdir -p caddy/html

# Check if any directories need sudo
if [ "$NEEDS_SUDO" = "1" ]; then
    echo ""
    echo "   ⚠️  Some directories are owned by root from previous Docker runs."
    echo "      To fix this, run:"
    echo "      sudo chown -R \$USER:\$USER odoo/ nextcloud/ open-sign-forms/ portainer/"
    echo "      Then run this script again."
    echo ""
    exit 1
fi

echo "   ✓ Directories created"

# Note: Mattermost uses named Docker volumes to avoid permission issues
# (The container runs as UID 2000 which doesn't match host user)

# ============================================
# Create Odoo configuration file
# ============================================
echo ""
echo "⚙️  Creating configuration files..."

cat > odoo/conf/odoo.conf << 'EOF'
[options]
; Database configuration
; NOTE: db_host, db_user, and db_password are set via environment variables
; HOST, USER, PASSWORD in docker-compose.yml
db_host = odoo-db
db_port = 5432
db_user = odoo
; db_password is set via PASSWORD environment variable
db_name = False

; Admin password for database management (change this!)
admin_passwd = admin

; Addons paths
addons_path = /mnt/extra-addons,/mnt/web,/mnt/report-engine,/mnt/manufacture,/mnt/purchase-workflow

; Data directory
data_dir = /var/lib/odoo

; Server settings
http_port = 8069
proxy_mode = True

; Logging
log_level = info

; Performance settings
workers = 2
max_cron_threads = 1
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 600
limit_time_real = 1200
EOF

echo "   ✓ Created odoo/conf/odoo.conf"

# ============================================
# Create .env file if it doesn't exist
# ============================================
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env file from template..."
    
    cat > .env << 'EOF'
# ===========================================
# Company Services Configuration
# ===========================================
# Copy this file to .env and modify the values

# ===========================================
# DOMAIN CONFIGURATION (REQUIRED)
# ===========================================
# Your base domain (e.g., example.com, mycompany.com)
BASE_DOMAIN=example.com

# Email for SSL certificate notifications
SSL_EMAIL=admin@example.com

# Subdomain prefixes for each service
ODOO_SUBDOMAIN=odoo
OPENSIGN_SUBDOMAIN=opensign
NEXTCLOUD_SUBDOMAIN=nextcloud
MATTERMOST_SUBDOMAIN=mattermost
PORTAINER_SUBDOMAIN=portainer

# ===========================================
# DATABASE PASSWORDS (CHANGE THESE!)
# ===========================================
# Odoo PostgreSQL
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo
POSTGRES_DB=postgres

# Nextcloud MariaDB
NEXTCLOUD_DB_ROOT_PASSWORD=nextcloud_root
NEXTCLOUD_DB_PASSWORD=nextcloud

# Mattermost PostgreSQL
MATTERMOST_DB_PASSWORD=mattermost

# ===========================================
# APPLICATION CREDENTIALS
# ===========================================
# Nextcloud admin account
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=admin

# ===========================================
# OPENSIGN CONFIGURATION
# ===========================================
# MongoDB connection (internal Docker network)
MONGODB_URI=mongodb://opensign-mongo:27017/opensign

# Application ID and keys (generate unique values for production!)
# You can generate these with: openssl rand -hex 32
OPENSIGN_APPID=opensignappid
OPENSIGN_MASTERKEY=opensignmasterkey
OPENSIGN_JAVASCRIPTKEY=opensignjavascriptkey
OPENSIGN_RESTKEY=opensignrestkey
OPENSIGN_FILEKEY=opensignfilekey

# ===========================================
# OTHER SETTINGS
# ===========================================
# Timezone
TZ=Europe/Madrid

# Docker network name
DOCKER_NETWORK=company_network
EOF

    echo "   ✓ Created .env file"
    echo ""
    echo "   ⚠️  IMPORTANT: Edit .env and change:"
    echo "      - BASE_DOMAIN to your actual domain"
    echo "      - SSL_EMAIL to your email"
    echo "      - All passwords to secure values"
else
    echo ""
    echo "   ℹ️  .env file already exists, skipping..."
fi

# ============================================
# Summary
# ============================================
echo ""
echo "============================================"
echo "✅ Initialization complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Edit your .env file with your domain and passwords:"
echo "   nano .env"
echo ""
echo "2. Configure your DNS to point to this server:"
echo "   - ${ODOO_SUBDOMAIN:-odoo}.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo "   - ${OPENSIGN_SUBDOMAIN:-opensign}.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo "   - ${NEXTCLOUD_SUBDOMAIN:-nextcloud}.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo "   - ${MATTERMOST_SUBDOMAIN:-mattermost}.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo "   - ${PORTAINER_SUBDOMAIN:-portainer}.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo "   Or use a wildcard: *.\${BASE_DOMAIN} → YOUR_SERVER_IP"
echo ""
echo "3. Start the services:"
echo "   docker compose up -d"
echo ""
echo "4. Wait a few minutes for all services to initialize"
echo ""
echo "5. Access your services at https://[subdomain].[your-domain]"
echo ""

