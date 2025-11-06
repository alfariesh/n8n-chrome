# Dockerfile - n8n dengan Puppeteer support
FROM n8nio/n8n:latest

USER root

# Install system dependencies for Chrome/Puppeteer
# These libraries are required by Chromium on Alpine Linux
RUN apk add --no-cache \
    ca-certificates \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    dbus \
    udev \
    bash \
    curl

# Install n8n Puppeteer node and required plugins
RUN npm install -g n8n-nodes-puppeteer puppeteer-extra-plugin-user-preferences --unsafe-perm || true

# Configure Puppeteer to use system Chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

USER node

# Start n8n
CMD ["n8n"]
