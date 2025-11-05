FROM n8nio/n8n:latest

USER root

# Install dependencies + chromium + ffmpeg
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    ffmpeg \
    dumb-init \
    && ln -sf /usr/bin/chromium /usr/bin/google-chrome \
    && mkdir -p /home/node/.cache/puppeteer \
    && chown -R node:node /home/node

# Set Puppeteer path & prevent auto-download
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV N8N_PUPPETEER_NO_SANDBOX=true
ENV NODE_ENV=production

USER node

WORKDIR /home/node
EXPOSE 5678

ENTRYPOINT ["dumb-init", "--"]
CMD ["n8n", "start", "--tunnel", "--no-sandbox", "--disable-setuid-sandbox"]
