# Troubleshooting Guide

## Puppeteer "Running as root without --no-sandbox" Error

### Why this happens on VPS but not locally

The error typically occurs due to differences between local and VPS environments:

1. **Docker Security Policies**
   - VPS providers may have stricter AppArmor/SELinux policies
   - Different kernel security modules configuration
   - User namespace remapping settings

2. **Docker Runtime Differences**
   - Different Docker versions
   - Different container runtime (runc vs containerd)
   - Security profiles applied by hosting provider

3. **Resource Isolation**
   - VPS may enforce stricter cgroup limits
   - Different shared memory (`/dev/shm`) configuration

### Solution Applied

This repository includes an **automatic runtime patch** that:

1. Detects when running in Docker (via `/docker-custom-entrypoint.sh`)
2. Patches `n8n-nodes-puppeteer` at startup to inject Chrome flags:
   ```javascript
   {
     args: [
       '--no-sandbox',
       '--disable-setuid-sandbox', 
       '--disable-dev-shm-usage',
       '--disable-gpu',
       '--disable-accelerated-2d-canvas',
       '--no-first-run',
       '--no-zygote'
     ]
   }
   ```

### Verification Steps on VPS

After deploying, check if the patch was applied:

```bash
# Check container logs for patch confirmation
docker logs n8n 2>&1 | grep -i "patch"

# Should show:
# ✓ Puppeteer node patched for Docker
# OR
# ✓ Puppeteer node already patched
```

### Manual Verification

If you still encounter issues, verify the patched file:

```bash
# Enter the container
docker exec -it n8n sh

# Check if the file contains the sandbox flags
grep -A5 "no-sandbox" /opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer/dist/nodes/Puppeteer/Puppeteer.node.js

# You should see the injected args array
```

### Additional VPS-Specific Fixes

If the automatic patch doesn't work, try these manual fixes:

#### 1. Increase Shared Memory

In `docker-compose.yml`, ensure you have:
```yaml
services:
  n8n:
    shm_size: '2gb'  # Already included
```

#### 2. Add Security Options

Already included in `docker-compose.yml`:
```yaml
security_opt:
  - seccomp:unconfined
```

#### 3. Check Docker Daemon Config

On your VPS, check `/etc/docker/daemon.json`:
```json
{
  "userns-remap": "default"
}
```

If this is enabled, Chrome may have additional restrictions.

#### 4. Verify User Inside Container

```bash
docker exec n8n whoami
# Should output: node (not root)
```

### Still Having Issues?

1. **Check Docker version on VPS:**
   ```bash
   docker --version
   docker info | grep -i runtime
   ```

2. **Check kernel security modules:**
   ```bash
   docker exec n8n cat /proc/self/status | grep Seccomp
   ```

3. **Test Chromium manually:**
   ```bash
   docker exec n8n /usr/bin/chromium-browser --version
   docker exec n8n /usr/bin/chromium-browser --no-sandbox --headless --dump-dom https://example.com
   ```

4. **Check for AppArmor/SELinux:**
   ```bash
   # On VPS host
   docker info | grep -i security
   ```

### Emergency Fallback

If all else fails, you can force Puppeteer to always use sandbox flags by setting this in your n8n workflow's Code node:

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

// Your code here
await browser.close();
```

## Common VPS Providers

### DigitalOcean / Linode / Vultr
Usually work with default configuration after patch.

### AWS EC2 / Google Cloud / Azure
May require additional security group rules or IAM permissions for optimal performance.

### Shared Hosting / OpenVZ
May have restrictions on Chrome execution. Consider using serverless Puppeteer alternatives.

## Performance Tips for VPS

1. Use a VPS with at least **2GB RAM**
2. Enable swap if running low on memory
3. Monitor with `docker stats n8n`
4. Consider using Puppeteer's `headless: "new"` mode for better performance
