# Puppeteer Configuration for n8n Docker (Production Setup)

## ✨ Good News!

With the production setup, **n8n-nodes-puppeteer is pre-installed** in your Docker image! 
- No need to install via Community Nodes panel
- Puppeteer node available immediately after startup
- All Chrome dependencies and configurations are handled automatically

## Using Puppeteer Node (Recommended)

Simply search for "Puppeteer" in your workflow editor and add the node. The node provides:
- **Get Page Content**: Extract HTML from any URL
- **Get Screenshot**: Capture page screenshots
- **Get PDF**: Generate PDFs from web pages  
- **Run Custom Script**: Full Puppeteer API access

All browser configurations are handled automatically by the Docker setup!

## Advanced: Custom Scripts with Code Node

If you need to use Puppeteer directly in Code nodes, use these launch arguments:

```javascript
const browser = await puppeteer.launch({
  executablePath: '/usr/bin/chromium-browser',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-accelerated-2d-canvas',
    '--no-first-run',
    '--no-zygote',
    '--disable-gpu'
  ],
  headless: true
});
```

## Why These Arguments?

- `--no-sandbox` & `--disable-setuid-sandbox`: Disables Chrome's sandboxing (required in Docker)
- `--disable-dev-shm-usage`: Prevents /dev/shm space issues in Docker
- `--disable-accelerated-2d-canvas`: Reduces GPU usage
- `--no-first-run`: Skips first run wizards
- `--no-zygote`: Disables the zygote process (helps with namespace issues)
- `--disable-gpu`: Disables GPU hardware acceleration

## Docker Configuration Applied

The following changes have been made to fix Puppeteer in Docker:

1. **docker-compose.yml**:
   - Added `shm_size: '2gb'` to prevent shared memory issues
   - Added `seccomp:unconfined` to allow necessary system calls

2. **Dockerfile**:
   - Installed additional dependencies (udev, ttf-opensans)
   - Set proper environment variables for Chrome paths

## Rebuild Instructions

After making these changes, rebuild and restart your containers:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Testing Puppeteer

Create a test workflow in n8n with a Code node:

```javascript
const puppeteer = require('puppeteer');

const browser = await puppeteer.launch({
  executablePath: '/usr/bin/chromium-browser',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu'
  ],
  headless: true
});

const page = await browser.newPage();
await page.goto('https://example.com');
const title = await page.title();
await browser.close();

return { title };
```

## Troubleshooting

If you still encounter issues:

1. Check container logs: `docker-compose logs n8n`
2. Verify Chromium installation: `docker-compose exec n8n which chromium-browser`
3. Test Chrome manually: `docker-compose exec n8n chromium-browser --version`
4. Increase shared memory if needed: Change `shm_size: '2gb'` to `'4gb'`
