FROM n8nio/n8n:latest

USER root

# Update and install Chromium
RUN apk update && \
    apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji

# Set Puppeteer to use installed Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

USER node
WORKDIR /home/node
```

**Commit**

---

### **C. Tambah File `.dockerignore`** (Optional)

**Filename:** `.dockerignore`

**Content:**
```
node_modules
npm-debug.log
.git
.gitignore
README.md
