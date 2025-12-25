#!/bin/sh
set -e

# Set default values if environment variables are not provided
if [ -z "$WEBDAV_USERNAME" ]; then
    echo "Warning: WEBDAV_USERNAME not set. Using default: zotero"
    export WEBDAV_USERNAME="zotero"
fi

if [ -z "$WEBDAV_PASSWORD" ]; then
    echo "Warning: WEBDAV_PASSWORD not set. Using default: ZoteroPass!"
    export WEBDAV_PASSWORD="ZoteroPass!"
fi

echo "Generating .htpasswd file..."
# Create .htpasswd file using htpasswd (part of apache2-utils)
htpasswd -bc /etc/nginx/.htpasswd "$WEBDAV_USERNAME" "$WEBDAV_PASSWORD"

echo "Starting Nginx..."
# Execute the command passed to the container (default is nginx)
exec "$@"
