FROM alpine:latest

# Install Nginx, WebDAV modules, and htpasswd utilities
RUN apk add --no-cache \
    nginx \
    nginx-mod-http-dav-ext \
    apache2-utils \
    && mkdir -p /var/www/webdav \
    && mkdir -p /run/nginx

# Copy configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

# Grant execution permissions to the script
RUN chmod +x /entrypoint.sh

# Set default environment variables
ENV WEBDAV_USERNAME=zotero
ENV WEBDAV_PASSWORD=ZoteroPass!

# Expose port 80
EXPOSE 80

# Configure volume for persistence
VOLUME /var/www/webdav

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
