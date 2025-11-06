# n8n Self-Hosted dengan Puppeteer & PostgreSQL

Setup lengkap n8n self-hosted dengan dukungan Puppeteer untuk browser automation dan PostgreSQL sebagai database.

## Fitur

- ✅ n8n workflow automation
- ✅ PostgreSQL database untuk data persistence
- ✅ Puppeteer support untuk browser automation
- ✅ Chromium pre-installed
- ✅ Docker Compose untuk easy deployment
- ✅ Volume persistence untuk data

## Cara Deployment

### 1. Konfigurasi Environment Variables

Edit file `.env` dan sesuaikan kredensial:

```bash
# Ganti password default
POSTGRES_PASSWORD=your_secure_password
N8N_BASIC_AUTH_PASSWORD=your_admin_password
```

### 2. Build dan Jalankan

```bash
# Build image
docker-compose build

# Jalankan semua services
docker-compose up -d
```

### 3. Akses n8n

Buka browser dan akses:
- URL: http://localhost:5678
- Username: admin (atau sesuai .env)
- Password: sesuai yang di set di .env

**Note:** 
- Image Docker sudah termasuk Chromium browser dan semua dependencies yang diperlukan
- Plugin `n8n-nodes-puppeteer` sudah ter-install otomatis di dalam Docker image
- Tidak perlu install manual lagi, tinggal pakai langsung!

## Perintah Docker Compose

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop dan hapus volumes (HATI-HATI: akan menghapus data)
docker-compose down -v

# Lihat logs
docker-compose logs -f

# Lihat logs n8n saja
docker-compose logs -f n8n

# Restart services
docker-compose restart

# Rebuild setelah update Dockerfile
docker-compose up -d --build
```

## Struktur Folder

```
.
├── docker-compose.yml      # Konfigurasi services
├── Dockerfile              # Custom n8n image dengan Puppeteer
├── .env                    # Environment variables (jangan commit!)
├── .gitignore             # Git ignore file
└── README.md              # Dokumentasi ini
```

## Troubleshooting

### Puppeteer Error "Browser not found"

Jika Puppeteer tidak menemukan browser, pastikan environment variable sudah benar di Dockerfile:
- `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser`
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`

### PostgreSQL Connection Error

Pastikan service postgres sudah running dan healthy:
```bash
docker-compose ps
docker-compose logs postgres
```

### Port 5678 sudah digunakan

Ubah port di `.env`:
```
N8N_PORT=8080
```

Dan update port mapping di `docker-compose.yml` jika perlu.

## Update n8n atau Puppeteer Plugin

```bash
# Stop services
docker-compose down

# Rebuild image dengan --no-cache
docker-compose build --no-cache

# Start ulang
docker-compose up -d
```

## Backup Data

### Backup Database PostgreSQL

```bash
docker exec n8n-postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
cat backup_file.sql | docker exec -i n8n-postgres psql -U n8n -d n8n
```

### Backup n8n Data

```bash
docker cp n8n:/home/node/.n8n ./n8n_backup
```

## Production Tips

1. **Ganti semua password default** di `.env`
2. **Setup HTTPS** dengan reverse proxy (Nginx/Traefik)
3. **Regular backup** database dan n8n data
4. **Monitor resource usage** dengan `docker stats`
5. **Setup proper logging** dan monitoring
6. **Update image** secara berkala untuk security patches

## Lisensi

Setup ini menggunakan:
- n8n (Sustainable Use License)
- n8n-nodes-puppeteer (MIT License)
- PostgreSQL (PostgreSQL License)
