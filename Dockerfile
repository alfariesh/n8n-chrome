FROM n8nio/n8n:latest

USER root

RUN apk update && apk add --no-cache chromium nss freetype harfbuzz ca-certificates ttf-freefont font-noto-emoji

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Configure n8n to listen on all interfaces and use platform port
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=${PORT:-5678}

USER node

WORKDIR /home/node
