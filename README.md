# Full Company Installation

Complete Docker-based setup for company services with automatic SSL certificates via Caddy.

## Services Included

- **Odoo** - Enterprise Resource Planning (ERP) system with built-in calendar
- **OpenSign** - Digital signature and document management platform
- **Nextcloud** - File sharing, collaboration, and calendar (CalDAV/CardDAV)
- **Mattermost** - Team chat and collaboration platform
- **Portainer** - Docker container management UI
- **Caddy** - Modern reverse proxy with automatic HTTPS

## Features

✅ Automatic SSL/TLS certificates via Let's Encrypt (zero configuration!)  
✅ Single configuration file (`.env`)  
✅ Custom subdomain configuration  
✅ Automatic HTTPS redirects  
✅ Production-ready logging  
✅ Easy deployment and updates  
✅ Self-signed certificates for local development  
✅ WebSocket support out of the box  

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- A domain name pointing to your server (for production)
- Ports 80 and 443 open on your firewall

## Project Structure

All data is stored in relative directories for easy backup and migration:

```
full-company-installation/
├── docker-compose.yml          # Main orchestration file
├── .env.example                # Example environment configuration
├── LICENSE                     # MIT License
├── start.sh                    # Start script (Linux/macOS)
├── stop.sh                     # Stop script (Linux/macOS)
├── start.bat                   # Start script (Windows)
├── stop.bat                    # Stop script (Windows)
├── scripts/                    # Utility scripts
│   ├── init.sh                # Initialize directories and configs
│   ├── backup.sh              # Backup all services
│   └── restore.sh             # Restore from backup
├── caddy/                     # Caddy reverse proxy
│   ├── Dockerfile             # Custom Caddy build with envsubst
│   ├── Caddyfile              # Reverse proxy configuration
│   ├── entrypoint.sh          # Template processor
│   └── html/                  # Dashboard page template
├── odoo/                      # Odoo data (portable)
│   ├── db_data/               # PostgreSQL database files
│   ├── web_data/              # Odoo application data
│   ├── conf/                  # Odoo configuration files
│   └── addons/                # Custom Odoo addons
├── open-sign-forms/           # OpenSign data (portable)
│   ├── mongodb-data/          # MongoDB database files
│   └── opensign-files/        # Uploaded documents
├── nextcloud/                 # Nextcloud data (portable)
│   ├── db_data/               # MariaDB database files
│   ├── html/                  # Nextcloud application files
│   ├── data/                  # User files and uploads
│   ├── config/                # Nextcloud configuration
│   └── custom_apps/           # Installed Nextcloud apps
├── mattermost/                # Mattermost data (uses Docker volumes)
│   └── db_data/               # PostgreSQL database files
└── portainer/                 # Portainer data (portable)
    └── data/                  # Portainer configuration and data
```

**Benefits of this structure:**
- ✅ Easy to backup: Just tar the entire directory
- ✅ Easy to migrate: Copy to another server and run `docker compose up`
- ✅ Easy to version control: Exclude data directories via `.gitignore`
- ✅ Easy to inspect: All data accessible on the host filesystem

## Quick Start

### Option A: One-Command Start (Recommended)

**Linux/macOS:**
```bash
./start.sh
```

**Windows:**
```cmd
start.bat
```

These scripts will:
- Run initialization automatically (if needed)
- Create required directories
- Check for `.env` file and create from template if missing
- Start all Docker services

### Option B: Manual Start

#### 1. Run Initialization Script

```bash
# Linux/macOS
./scripts/init.sh

# Windows (run start.bat once, it will initialize for you)
```

This script will:
- Create all required directories
- Create the Odoo configuration file
- Create a `.env` file from template (if it doesn't exist)
- Check for permission issues

#### 2. Configure Your Environment

Edit the `.env` file with your settings:

```bash
nano .env  # or use your preferred editor
```

**Important settings to configure:**

```env
# Your domain configuration (this is all you need to change!)
BASE_DOMAIN=yourcompany.com

# Subdomain names (customize if desired)
ODOO_SUBDOMAIN=odoo
OPENSIGN_SUBDOMAIN=opensign
NEXTCLOUD_SUBDOMAIN=nextcloud
MATTERMOST_SUBDOMAIN=mattermost
PORTAINER_SUBDOMAIN=portainer

# SSL notifications
SSL_EMAIL=admin@yourcompany.com

# Change all passwords!
POSTGRES_PASSWORD=odoo_secure_password
NEXTCLOUD_ADMIN_PASSWORD=nextcloud_secure_password
NEXTCLOUD_DB_PASSWORD=nextcloud_db_secure_password
MATTERMOST_DB_PASSWORD=mattermost_secure_password

# OpenSign keys (generate with: openssl rand -hex 32)
OPENSIGN_MASTERKEY=your_secure_master_key
OPENSIGN_JAVASCRIPTKEY=your_secure_js_key
```

**Note:** All service URLs are automatically constructed from `BASE_DOMAIN` and the subdomain variables. No need to manually set URLs!

With the above configuration, your services will automatically be available at:
- Odoo: `https://odoo.yourcompany.com`
- OpenSign: `https://opensign.yourcompany.com`
- Nextcloud: `https://nextcloud.yourcompany.com`
- Mattermost: `https://mattermost.yourcompany.com`
- Portainer: `https://portainer.yourcompany.com`

### 3. Configure DNS

Point your domain and subdomains to your server's IP address:

```
A Record: odoo.yourcompany.com       -> YOUR_SERVER_IP
A Record: opensign.yourcompany.com   -> YOUR_SERVER_IP
A Record: nextcloud.yourcompany.com  -> YOUR_SERVER_IP
A Record: mattermost.yourcompany.com -> YOUR_SERVER_IP
A Record: portainer.yourcompany.com  -> YOUR_SERVER_IP
```

Or use a wildcard DNS record:

```
A Record: *.yourcompany.com -> YOUR_SERVER_IP
```

#### 4. Start the Services

**Using the start script (recommended):**
```bash
# Linux/macOS
./start.sh

# Windows
start.bat
```

**Or using Docker Compose directly:**
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

**To stop services:**
```bash
# Linux/macOS
./stop.sh

# Windows
stop.bat

# Or directly
docker compose down
```

### 5. Access Your Services

After a few minutes for SSL certificates to be generated:

- **Odoo**: `https://odoo.yourcompany.com`
  - First time setup: Follow the Odoo configuration wizard
  - Master password: Check `odoo/master-password.txt`

- **OpenSign**: `https://opensign.yourcompany.com`
  - First time setup: Create your admin account

- **Nextcloud**: `https://nextcloud.yourcompany.com`
  - First time setup: Use admin credentials from `.env` file
  - Username: Value of `NEXTCLOUD_ADMIN_USER`
  - Password: Value of `NEXTCLOUD_ADMIN_PASSWORD`

- **Mattermost**: `https://mattermost.yourcompany.com`
  - First time setup: Create your admin account
  - Follow the setup wizard to configure your team

- **Portainer**: `https://portainer.yourcompany.com`
  - First time setup: Create admin password (required on first login)
  - Use to manage all Docker containers via web UI

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `BASE_DOMAIN` | Your main domain | `example.com` | ✅ Yes |
| `SSL_EMAIL` | Email for SSL certificates | `admin@example.com` | ✅ Yes |
| `ODOO_SUBDOMAIN` | Subdomain for Odoo | `odoo` | Optional |
| `OPENSIGN_SUBDOMAIN` | Subdomain for OpenSign | `opensign` | Optional |
| `NEXTCLOUD_SUBDOMAIN` | Subdomain for Nextcloud | `nextcloud` | Optional |
| `MATTERMOST_SUBDOMAIN` | Subdomain for Mattermost | `mattermost` | Optional |
| `PORTAINER_SUBDOMAIN` | Subdomain for Portainer | `portainer` | Optional |
| `TZ` | Timezone | `Europe/Madrid` | Optional |
| `POSTGRES_PASSWORD` | Odoo database password | - | ✅ Yes |
| `NEXTCLOUD_ADMIN_USER` | Nextcloud admin username | `admin` | Optional |
| `NEXTCLOUD_ADMIN_PASSWORD` | Nextcloud admin password | - | ✅ Yes |
| `NEXTCLOUD_DB_PASSWORD` | Nextcloud database password | - | ✅ Yes |
| `MATTERMOST_DB_PASSWORD` | Mattermost database password | - | ✅ Yes |
| `OPENSIGN_APPID` | OpenSign application ID | `opensignappid` | Optional |
| `OPENSIGN_MASTERKEY` | OpenSign master key | - | ✅ Yes (production) |
| `OPENSIGN_JAVASCRIPTKEY` | OpenSign JavaScript key | - | ✅ Yes (production) |

**Note:** All service URLs are automatically constructed. For example, Odoo will be accessible at `https://${ODOO_SUBDOMAIN}.${BASE_DOMAIN}` (e.g., `https://odoo.yourcompany.com`).

### SSL/TLS Certificate Management

Caddy automatically handles SSL certificates with **zero configuration**:

- **Production (real domains)**: Automatically obtains Let's Encrypt certificates
- **Development (.localhost domains)**: Uses self-signed certificates

Certificates are automatically:
- Generated on first startup
- Renewed before expiry (Caddy handles this internally)
- Stored in Docker volumes for persistence

**No manual intervention required!** This is one of Caddy's biggest advantages over traditional setups.

## Management

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f odoo-web
docker compose logs -f opensign-server
docker compose logs -f nextcloud
docker compose logs -f mattermost
docker compose logs -f portainer
docker compose logs -f caddy
```

### Restart Services

```bash
# All services
docker compose restart

# Specific service
docker compose restart odoo-web
docker compose restart caddy
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ WARNING: This deletes all data!)
docker compose down -v
```

### Update Services

```bash
# Pull latest images
docker compose pull

# Rebuild custom images (Caddy)
docker compose build

# Restart with new images
docker compose up -d
```

### Backup

#### Simple Backup (Recommended)

Since all data is stored in relative paths, you can simply backup the entire directory:

```bash
# Backup everything
cd ..
tar czf company-backup-$(date +%Y%m%d).tar.gz full-company-installation/ --exclude='full-company-installation/.git'

# Or use the included backup script
cd full-company-installation
bash scripts/backup.sh
```

#### Backup Individual Services

**Backup Odoo:**

```bash
# Backup Odoo database
docker exec odoo-db pg_dump -U odoo postgres | gzip > backup_odoo_$(date +%Y%m%d).sql.gz

# Or just backup the data directory
tar czf odoo_backup_$(date +%Y%m%d).tar.gz odoo/
```

**Backup OpenSign:**

```bash
# Backup OpenSign database
docker exec opensign-mongo mongodump --out=/data/backup
docker cp opensign-mongo:/data/backup ./backup_opensign_$(date +%Y%m%d)

# Or just backup the data directory
tar czf opensign_backup_$(date +%Y%m%d).tar.gz open-sign-forms/
```

**Backup Nextcloud:**

```bash
# Backup Nextcloud database
docker exec nextcloud-db mysqldump -u nextcloud -p${NEXTCLOUD_DB_PASSWORD} nextcloud | gzip > backup_nextcloud_$(date +%Y%m%d).sql.gz

# Or just backup the data directory
tar czf nextcloud_backup_$(date +%Y%m%d).tar.gz nextcloud/
```

**Backup Mattermost:**

```bash
# Backup Mattermost database
docker exec mattermost-db pg_dump -U mattermost mattermost | gzip > backup_mattermost_$(date +%Y%m%d).sql.gz

# Note: Mattermost uses Docker volumes for data
docker run --rm -v full-company-installation_mattermost_data:/data -v $(pwd):/backup alpine tar czf /backup/mattermost_data_$(date +%Y%m%d).tar.gz -C /data .
```

**Backup Portainer:**

```bash
# Backup Portainer data
tar czf portainer_backup_$(date +%Y%m%d).tar.gz portainer/
```

### Migration to Another Server

Thanks to the relative path structure, migration is simple:

```bash
# On the old server:
# 1. Stop services
docker compose down

# 2. Create backup
tar czf company-backup.tar.gz .

# 3. Transfer to new server
scp company-backup.tar.gz user@newserver:/path/to/destination/

# On the new server:
# 1. Extract backup
tar xzf company-backup.tar.gz
cd full-company-installation

# 2. Update .env if server IP or domains changed
nano .env

# 3. Start services
docker compose up -d
```

## Troubleshooting

### SSL Certificates Not Working

1. **Check DNS propagation**: Ensure your domain points to the server
   ```bash
   nslookup odoo.yourcompany.com
   ```

2. **Check Caddy logs**:
   ```bash
   docker compose logs caddy
   ```

3. **Verify port 80 is accessible**: Let's Encrypt needs port 80 for challenges
   ```bash
   curl -I http://yourserver-ip
   ```

4. **Check Caddy is running**:
   ```bash
   docker compose ps caddy
   ```

### Service Not Accessible

1. **Check service is running**:
   ```bash
   docker compose ps
   ```

2. **Check service logs**:
   ```bash
   docker compose logs [service-name]
   ```

3. **Verify Caddy routing**:
   ```bash
   docker compose logs caddy | grep -i error
   ```

4. **Test Caddy configuration**:
   ```bash
   docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
   ```

### Odoo Connection Issues

If Odoo cannot connect to the database:

```bash
# Check database is running
docker compose ps odoo-db

# Check database logs
docker compose logs odoo-db

# Verify credentials in .env match odoo/conf/odoo.conf
```

### OpenSign Issues

If OpenSign isn't working:

```bash
# Check server logs
docker compose logs opensign-server

# Check client logs
docker compose logs opensign-client

# Verify MongoDB is running
docker compose ps opensign-mongo
```

### Mattermost Permission Errors

Mattermost uses Docker named volumes to avoid permission issues. If you see permission errors:

```bash
# Remove and recreate volumes
docker compose down
docker volume rm full-company-installation_mattermost_config
docker volume rm full-company-installation_mattermost_data
docker compose up -d mattermost
```

### Portainer "API Version Too Old" Error

If Portainer shows an error like `"client version 1.41 is too old. Minimum supported API version is 1.44"`, this is a known issue with Docker 29.x and Portainer ([GitHub issue #12925](https://github.com/portainer/portainer/issues/12925)).

**Fix:**

1. Edit the Docker service configuration:
   ```bash
   sudo systemctl edit docker.service
   ```

2. Add the following lines **above** the line that says `### Lines below this comment will be discarded`:
   ```ini
   [Service]
   Environment=DOCKER_MIN_API_VERSION=1.24
   ```

3. Save and exit, then restart Docker:
   ```bash
   sudo systemctl restart docker
   ```

4. Restart Portainer:
   ```bash
   docker compose restart portainer
   ```

This configures Docker to accept older API versions, which Portainer uses by default.

### Reset Everything

```bash
# Stop all services
docker compose down

# Remove all volumes (⚠️ WARNING: Deletes all data!)
docker compose down -v

# Start fresh
./scripts/init.sh
docker compose up -d
```

## Security Recommendations

1. **Change default passwords** in `.env` file
2. **Use strong passwords** for all services (minimum 16 characters)
3. **Generate secure OpenSign keys**: `openssl rand -hex 32`
4. **Regular backups** of databases and files
5. **Keep services updated**: Run `docker compose pull` regularly
6. **Configure firewall**: Only allow ports 80, 443, and 22 (SSH)
7. **Monitor logs** regularly for suspicious activity
8. **Enable 2FA** where available (Nextcloud, Mattermost, etc.)

## Network Architecture

```
Internet (Ports 80/443)
         ↓
    Caddy (Reverse Proxy + Auto SSL)
         ↓
    ┌────┴────┬───────┬────────┬──────────┬──────────┐
    ↓         ↓       ↓        ↓          ↓          
Odoo:8069  OpenSign Nextcloud Mattermost Portainer
           :3000    :80      :8065      :9000
    ↓      :8080
    ↓         ↓       ↓        ↓          
PostgreSQL MongoDB MariaDB PostgreSQL    
:5432     :27017  :3306   :5432         
                    ↓
                  Redis
```

All services communicate through the internal `company_network` Docker network.

**Exposed Ports:**
- `80` - HTTP (redirects to HTTPS via Caddy)
- `443` - HTTPS (all services via Caddy)

## Why Caddy?

This installation uses **Caddy** as the reverse proxy, providing several advantages:

✅ **Automatic HTTPS** - Zero-configuration SSL certificates from Let's Encrypt  
✅ **Simple configuration** - Human-readable Caddyfile syntax  
✅ **Auto-renewal** - Certificates renew automatically, no cron jobs needed  
✅ **HTTP/2 & HTTP/3** - Modern protocols enabled by default  
✅ **WebSocket support** - Works out of the box for Mattermost, Portainer  
✅ **Single binary** - No dependencies, minimal attack surface  
✅ **Graceful reloads** - Zero-downtime configuration changes  

Example Caddyfile configuration:
```caddyfile
odoo.example.com {
    reverse_proxy odoo-web:8069
}
```

That's all you need! Caddy handles SSL, redirects, and headers automatically.

## Support

For issues with:
- **Odoo**: [Odoo Documentation](https://www.odoo.com/documentation)
- **OpenSign**: [OpenSign GitHub](https://github.com/OpenSignLabs/OpenSign)
- **Nextcloud**: [Nextcloud Documentation](https://docs.nextcloud.com/)
- **Mattermost**: [Mattermost Documentation](https://docs.mattermost.com/)
- **Portainer**: [Portainer Documentation](https://docs.portainer.io/)
- **Caddy**: [Caddy Documentation](https://caddyserver.com/docs/)

## License

This configuration is provided as-is for deploying open-source and commercial software. Please refer to individual service licenses:
- Odoo: LGPL-3.0 (Community) / Commercial (Enterprise)
- OpenSign: AGPL-3.0
- Nextcloud: AGPL-3.0
- Mattermost: MIT (Team Edition) / Commercial (Enterprise)
- Portainer: Zlib (Community) / Commercial (Business)
- Caddy: Apache-2.0

## Project Maintenance

This project combines:
- **Odoo** - ERP system for business management with calendar
- **OpenSign** - Digital document signing
- **Nextcloud** - File sharing, collaboration, and calendar sync
- **Mattermost** - Team chat and collaboration
- **Portainer** - Docker management interface
- **Caddy** - Modern reverse proxy with automatic HTTPS

All services are containerized and orchestrated with Docker Compose for easy deployment and management.

## Service Highlights

### Odoo Calendar Features
- **Built-in Calendar** - Schedule meetings, tasks, and events
- **Team Scheduling** - See availability across your organization
- **Integration** - Syncs with projects, CRM, and other Odoo modules
- **Mobile Access** - Odoo mobile app for iOS/Android
- **Email Integration** - Send/receive meeting invitations

### Nextcloud Calendar Features
- **CalDAV/CardDAV** - Sync with any calendar app (iPhone, Android, Thunderbird, etc.)
- **Shared Calendars** - Team calendars with permissions
- **Calendar App** - Built-in web interface for managing events
- **Contacts Integration** - Address book with CardDAV sync
- **Mobile Sync** - Native sync with iOS/Android calendar apps

### Mattermost
- Team chat with channels and direct messages
- File sharing and search
- Mobile apps available
- Integrations with many tools
- Alternative to Slack
- Calendar integrations available via plugins

### Portainer
- Manage all Docker containers via web UI
- View logs, stats, and resource usage
- Deploy new containers easily
- Backup and restore configurations
- Access at `https://portainer.yourcompany.com`

## Nextcloud Tips

### Increase Upload Size

To increase the maximum upload size in Nextcloud, create a custom PHP configuration:

```bash
mkdir -p nextcloud/config
echo "upload_max_filesize = 16G" > nextcloud/config/upload.ini
echo "post_max_size = 16G" >> nextcloud/config/upload.ini
echo "max_execution_time = 3600" >> nextcloud/config/upload.ini
echo "max_input_time = 3600" >> nextcloud/config/upload.ini
docker compose restart nextcloud
```

### Install Nextcloud Apps

After first login:
1. Go to user menu (top right) → **Apps**
2. Recommended apps:
   - **Calendar** - Schedule and manage events
   - **Contacts** - Address book
   - **Deck** - Kanban-style project management
   - **Talk** - Video calls and chat
   - **Mail** - Email client
   - **OnlyOffice** or **Collabora** - Office document editing

### Configure External Storage

Nextcloud can connect to external storage (S3, FTP, SMB, etc.):
1. Enable **External storage support** app
2. Settings → Administration → External storage
3. Add your storage backend

### Enable Two-Factor Authentication

For better security:
1. Install **Two-Factor TOTP Provider** app
2. Settings → Security → Two-Factor Authentication
3. Enable for all users or specific groups

## Calendar Integration Guide

Your installation includes **two calendar solutions** that work together:

### Odoo Calendar (Business Scheduling)

**Best for:**
- Company-wide meeting scheduling
- Resource booking (meeting rooms, equipment)
- Integration with CRM, projects, and tasks
- Employee availability management

**How to use:**
1. Go to `https://odoo.yourcompany.com`
2. Navigate to **Calendar** module
3. Create events, invite attendees
4. Access via Odoo mobile app (iOS/Android)

### Nextcloud Calendar (Personal & Team Calendars)

**Best for:**
- Personal calendar management
- Team/shared calendars
- Mobile device synchronization
- Integration with any CalDAV-compatible app

**Setup on Mobile (iOS):**
1. Go to Nextcloud Settings → Security
2. Generate an "App password" for your device
3. On iPhone: Settings → Calendar → Accounts → Add Account
4. Select **Other** → **Add CalDAV Account**
   - Server: `nextcloud.yourcompany.com`
   - Username: Your Nextcloud username
   - Password: The app password you generated
5. Your calendars will sync automatically!

**Setup on Mobile (Android):**
1. Install **DAVx⁵** app from Play Store (free)
2. Open DAVx⁵, add new account
3. Select **Login with URL and username**
   - Base URL: `https://nextcloud.yourcompany.com`
   - Username: Your Nextcloud username
   - Password: Your Nextcloud password (or app password)
4. Select which calendars/contacts to sync

**Desktop Sync (Thunderbird, Outlook, etc.):**
1. In Nextcloud, go to Calendar app
2. Click settings (⚙️) next to a calendar
3. Copy the CalDAV link
4. Add to your desktop calendar app using the CalDAV URL

**Sharing Calendars:**
1. In Nextcloud Calendar, click share icon next to calendar
2. Enter username or create public link
3. Set permissions (view only or edit)
4. Team members can subscribe to shared calendars

### Using Both Systems Together

**Recommended Setup:**
- **Odoo**: Company meetings, resource scheduling, customer appointments
- **Nextcloud**: Personal calendars, team calendars, mobile sync

Both systems work independently, so you can use one or both depending on your needs!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note:** The individual services (Odoo, OpenSign, Nextcloud, Mattermost, Portainer, Caddy) have their own licenses. This license applies only to the Docker Compose configuration and scripts in this repository.
