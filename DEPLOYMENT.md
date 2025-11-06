# Deployment Guide

## Deployment ke VPS / Cloud Platform

### Prerequisites

- Docker dan Docker Compose installed
- Domain name (opsional tapi recommended)
- Minimal 2GB RAM
- Git installed

---

## 1. Deployment Standard (VPS dengan Docker)

### Step 1: Clone Repository

```bash
git clone https://github.com/alfariesh/n8n-chrome.git
cd n8n-chrome
```

### Step 2: Configure Environment Variables

```bash
# Copy template
cp .env.example .env

# Edit dengan editor favorit
nano .env  # atau vim, vi, dll
```

**PENTING:** Update nilai berikut:

```bash
# Database Password
POSTGRES_PASSWORD=your_secure_db_password_here

# n8n Admin Password  
N8N_BASIC_AUTH_PASSWORD=your_secure_admin_password_here

# Domain Configuration (CRITICAL!)
N8N_HOST=your-domain.com  # Ganti dengan domain Anda
N8N_PROTOCOL=https        # Gunakan https jika sudah setup SSL
WEBHOOK_URL=https://your-domain.com/  # HARUS domain publik, BUKAN localhost!
```

### Step 3: Build dan Deploy

```bash
# Build image
docker-compose build --no-cache

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f n8n
```

### Step 4: Verify Deployment

```bash
# Check if patch was applied
docker logs n8n 2>&1 | grep -i "patch"
# Should show: ✓ Puppeteer node patched for Docker

# Check if services are running
docker-compose ps

# Test access
curl -I http://your-domain.com
```

---

## 2. Deployment ke Zeabur

Zeabur adalah platform PaaS yang support Docker deployment.

### Important Notes for Zeabur:

1. **Port Configuration**
   - Zeabur automatically assigns ports
   - Make sure your `docker-compose.yml` exposes the correct port
   - Default n8n port: `5678`

2. **Environment Variables**
   
   Set these in Zeabur dashboard:
   
   ```bash
   # Database
   POSTGRES_USER=n8n
   POSTGRES_PASSWORD=<generate-strong-password>
   POSTGRES_DB=n8n
   
   # n8n Config
   N8N_PORT=8080  # Check Zeabur docs for correct port
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=<your-admin-password>
   
   # ⚠️ CRITICAL: Use public domain, NOT localhost!
   N8N_HOST=your-app.zeabur.app
   N8N_PROTOCOL=https
   WEBHOOK_URL=https://your-app.zeabur.app/
   
   # Puppeteer
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
   CHROME_BIN=/usr/bin/chromium-browser
   
   # Timezone
   GENERIC_TIMEZONE=Asia/Jakarta
   ```

3. **Webhook Configuration**
   
   ⚠️ **PENTING:** `WEBHOOK_URL` HARUS menggunakan domain publik Anda!
   
   ❌ **SALAH:**
   ```bash
   WEBHOOK_URL=http://localhost:8080/
   ```
   
   ✅ **BENAR:**
   ```bash
   WEBHOOK_URL=https://n8n-puppeteer.zeabur.app/
   ```
   
   Jika `WEBHOOK_URL` salah, webhooks tidak akan berfungsi karena external services tidak bisa reach `localhost`.

4. **Database Connection**
   
   Zeabur mungkin provide managed PostgreSQL. Jika iya:
   - Use Zeabur's PostgreSQL connection string
   - Update `docker-compose.yml` accordingly
   - Or use environment variables untuk override

### Zeabur Deployment Steps:

1. **Push to GitHub** (already done)

2. **Connect to Zeabur:**
   - Login ke Zeabur dashboard
   - Create new project
   - Connect GitHub repository
   - Select `n8n-chrome` repo

3. **Configure Environment Variables** di Zeabur dashboard

4. **Deploy** dan wait for build

5. **Verify:**
   ```bash
   # Check logs in Zeabur dashboard
   # Look for: ✓ Puppeteer node patched for Docker
   ```

---

## 3. Deployment dengan Reverse Proxy (Nginx)

Jika deploy di VPS standard dengan domain sendiri:

### Install Nginx

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

### Configure Nginx

Create `/etc/nginx/sites-available/n8n`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Important for webhooks
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Setup SSL with Let's Encrypt

```bash
sudo certbot --nginx -d your-domain.com
```

### Update .env

```bash
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com/
```

Restart n8n:
```bash
docker-compose restart
```

---

## 4. Common Issues

### Issue: Puppeteer fails with "Running as root without --no-sandbox"

**Solution:** Already handled by automatic patch in this repo.

Verify:
```bash
docker logs n8n 2>&1 | grep -i "patch"
```

If not patched, rebuild:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Issue: Webhooks not working

**Cause:** `WEBHOOK_URL` is set to `localhost`

**Solution:** Change to your public domain:
```bash
WEBHOOK_URL=https://your-public-domain.com/
```

### Issue: Can't access n8n from browser

**Check:**
1. Firewall rules allow port 80/443
2. Nginx is running: `sudo systemctl status nginx`
3. Docker containers are up: `docker-compose ps`
4. DNS points to your server IP

### Issue: Database connection failed

**Check:**
1. PostgreSQL container is healthy: `docker-compose ps`
2. Credentials in `.env` match
3. Database initialized: `docker-compose logs postgres`

---

## 5. Post-Deployment Checklist

- [ ] Change all default passwords in `.env`
- [ ] `WEBHOOK_URL` uses public domain (not localhost)
- [ ] SSL certificate installed (for production)
- [ ] Firewall configured properly
- [ ] Backup strategy in place
- [ ] Monitor logs: `docker-compose logs -f`
- [ ] Test Puppeteer node with simple workflow
- [ ] Test webhook with external service

---

## 6. Monitoring & Maintenance

### Check Resource Usage

```bash
docker stats n8n n8n-postgres
```

### View Logs

```bash
# All services
docker-compose logs -f

# n8n only
docker-compose logs -f n8n

# Last 100 lines
docker-compose logs --tail=100 n8n
```

### Backup Database

```bash
docker exec n8n-postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql
```

### Update n8n

```bash
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## Need Help?

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed debugging guide.
