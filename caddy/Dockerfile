FROM caddy:alpine

# Install envsubst (part of gettext package)
RUN apk add --no-cache gettext

# Create directories
RUN mkdir -p /srv/templates /srv/html

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy HTML templates
COPY html/ /srv/templates/

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

