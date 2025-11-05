FROM n8nio/n8n:latest

USER root

RUN apk update && apk add --no-cache chromium nss freetype harfbuzz ca-certificates ttf-freefont font-noto-emoji

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

USER node

WORKDIR /home/node
