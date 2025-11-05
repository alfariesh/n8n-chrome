FROM n8nio/n8n:latest

USER root

# Install Chromium, FFmpeg, dan font basic agar Puppeteer bisa render halaman
RUN apt-get update && \
    apt-get install -y chromium ffmpeg fonts-freefont-ttf && \
    ln -sf /usr/bin/chromium /usr/bin/google-chrome && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables agar Puppeteer tahu path & flags yang benar
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"
ENV CHROME_PATH="/usr/bin/chromium"
ENV CHROME_BIN="/usr/bin/chromium"
ENV N8N_PUPPETEER_NO_SANDBOX=true
ENV PUPPETEER_ARGS="--no-sandbox --disable-setuid-sandbox"

USER node

# Expose port & startup command
EXPOSE 5678
CMD ["n8n", "start", "--tunnel", "--no-sandbox", "--disable-setuid-sandbox"]
