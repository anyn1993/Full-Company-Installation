#!/bin/sh
# Caddy Entrypoint Script
# Processes HTML templates with environment variables, then starts Caddy

set -e

echo "🚀 Starting Caddy with environment variable substitution..."

# Create processed HTML directory
mkdir -p /srv/html

# Set default values if not provided
export BASE_DOMAIN=${BASE_DOMAIN:-example.com}
export ODOO_SUBDOMAIN=${ODOO_SUBDOMAIN:-odoo}
export OPENSIGN_SUBDOMAIN=${OPENSIGN_SUBDOMAIN:-opensign}
export NEXTCLOUD_SUBDOMAIN=${NEXTCLOUD_SUBDOMAIN:-nextcloud}
export MATTERMOST_SUBDOMAIN=${MATTERMOST_SUBDOMAIN:-mattermost}
export PORTAINER_SUBDOMAIN=${PORTAINER_SUBDOMAIN:-portainer}

echo "📝 Processing templates with:"
echo "   BASE_DOMAIN: $BASE_DOMAIN"
echo "   ODOO_SUBDOMAIN: $ODOO_SUBDOMAIN"
echo "   OPENSIGN_SUBDOMAIN: $OPENSIGN_SUBDOMAIN"
echo "   NEXTCLOUD_SUBDOMAIN: $NEXTCLOUD_SUBDOMAIN"
echo "   MATTERMOST_SUBDOMAIN: $MATTERMOST_SUBDOMAIN"
echo "   PORTAINER_SUBDOMAIN: $PORTAINER_SUBDOMAIN"
echo ""

# Process all HTML files in templates directory
for template in /srv/templates/*.html; do
    if [ -f "$template" ]; then
        filename=$(basename "$template")
        echo "   ✓ Processing $filename..."
        
        # Use envsubst to replace ${VAR} placeholders with actual values
        envsubst '${BASE_DOMAIN} ${ODOO_SUBDOMAIN} ${OPENSIGN_SUBDOMAIN} ${NEXTCLOUD_SUBDOMAIN} ${MATTERMOST_SUBDOMAIN} ${PORTAINER_SUBDOMAIN}' \
            < "$template" \
            > "/srv/html/$filename"
    fi
done

# Copy any non-HTML files (CSS, JS, images) directly
for file in /srv/templates/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        extension="${filename##*.}"
        if [ "$extension" != "html" ]; then
            cp "$file" "/srv/html/$filename"
        fi
    fi
done

echo ""
echo "✅ Templates processed successfully!"
echo ""
echo "🌐 Services will be available at:"
echo "   - https://${ODOO_SUBDOMAIN}.${BASE_DOMAIN}"
echo "   - https://${OPENSIGN_SUBDOMAIN}.${BASE_DOMAIN}"
echo "   - https://${NEXTCLOUD_SUBDOMAIN}.${BASE_DOMAIN}"
echo "   - https://${MATTERMOST_SUBDOMAIN}.${BASE_DOMAIN}"
echo "   - https://${PORTAINER_SUBDOMAIN}.${BASE_DOMAIN}"
echo "   - https://${BASE_DOMAIN} (dashboard)"
echo ""
echo "🔐 SSL certificates will be automatically obtained from Let's Encrypt"
echo ""
echo "🚀 Starting Caddy..."

# Start Caddy with the original command
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

