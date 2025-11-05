FROM n8nio/n8n:latest

USER root

RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    ffmpeg \
    && ln -sf /usr/bin/chromium /usr/bin/google-chrome \
    && rm -rf /var/cache/apk/*

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

USER node

EXPOSE 5678
CMD ["n8n", "start", "--tunnel", "--no-sandbox", "--disable-setuid-sandbox"]
