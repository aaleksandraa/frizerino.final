# 🚀 Frizerino - Deployment Uputstvo za Hetzner + Plesk

## Sadržaj
1. [Struktura Projekta i GitHub](#1-struktura-projekta-i-github)
2. [Priprema Servera na Hetzneru](#2-priprema-servera-na-hetzneru)
3. [Konfiguracija Plesk-a](#3-konfiguracija-plesk-a)
4. [Deployment Backend-a (Laravel)](#4-deployment-backend-a-laravel)
5. [Deployment Frontend-a (React)](#5-deployment-frontend-a-react)
6. [Baza Podataka (PostgreSQL)](#6-baza-podataka-postgresql)
7. [Redis Instalacija i Konfiguracija](#7-redis-instalacija-i-konfiguracija)
8. [Queue Worker (Supervisor)](#8-queue-worker-supervisor)
9. [SSL Certifikati](#9-ssl-certifikati)
10. [Cron Jobs](#10-cron-jobs)
11. [Email Konfiguracija](#11-email-konfiguracija)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Struktura Projekta i GitHub

### 1.1 GitHub Struktura - PREPORUČENO: Jedan Repository

Preporučujem **jedan repository** za cijeli projekat jer:
- Lakše upravljanje verzijama
- Backend i frontend su povezani
- Jednostavniji deployment

```
FrizerskiSaloni/          ← Root repozitorija
├── backend/              ← Laravel API
├── frontend/             ← React aplikacija
├── DEPLOYMENT.md         ← Ovo uputstvo
├── .gitignore            ← Globalni gitignore
└── README.md
```

### 1.2 Kreiranje .gitignore u root-u

Kreiraj `.gitignore` u root folderu:

```gitignore
# Backend
backend/vendor/
backend/node_modules/
backend/.env
backend/storage/*.key
backend/storage/logs/*.log
backend/storage/framework/cache/*
backend/storage/framework/sessions/*
backend/storage/framework/views/*
backend/bootstrap/cache/*

# Frontend
frontend/node_modules/
frontend/dist/
frontend/.env
frontend/.env.local
frontend/.env.production

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

### 1.3 Inicijalizacija Git Repozitorija

```powershell
# U root folderu FrizerskiSaloni
cd c:\Users\aleks\Desktop\FrizerskiSaloni

# Inicijaliziraj git
git init

# Dodaj sve fajlove
git add .

# Prvi commit
git commit -m "Initial commit - Frizerino platform"

# Kreiraj repo na GitHub-u (github.com/new)
# Ime: frizerino ili frizerski-saloni

# Poveži sa GitHub-om
git remote add origin https://github.com/TVOJ_USERNAME/frizerino.git

# Push na GitHub
git branch -M main
git push -u origin main
```

---

## 2. Priprema Servera na Hetzneru

### 2.1 Naručivanje Servera

1. Idi na [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Kreiraj novi projekat: "Frizerino"
3. Dodaj server:
   - **Location**: Falkenstein ili Nuremberg (bliže BiH)
   - **OS**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 4GB RAM) - minimalno za produkciju
   - **Networking**: Public IPv4
   - **SSH Key**: Dodaj svoj SSH ključ

### 2.2 Instalacija Plesk-a

Povežite se na server preko SSH:

```bash
ssh root@TVOJA_IP_ADRESA
```

Instaliraj Plesk:

```bash
# Download i instalacija Plesk-a
sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O - https://autoinstall.plesk.com/one-click-installer)
```

Ovo će trajati 15-30 minuta. Na kraju ćeš dobiti link za pristup Plesk panelu.

### 2.3 Plesk Inicijalna Konfiguracija

1. Otvori: `https://TVOJA_IP:8443`
2. Uloguj se sa root kredencijalima
3. Kreiraj admin nalog
4. Aktiviraj licencu (možeš koristiti trial ili kupiti)

---

## 3. Konfiguracija Plesk-a

### 3.1 Instalacija Potrebnih Ekstenzija

U Plesk-u idi na **Extensions** i instaliraj:
- ✅ **Git** - za deployment
- ✅ **Let's Encrypt** - za SSL
- ✅ **Node.js** - za frontend build
- ✅ **Redis** - za caching i queue

### 3.2 Kreiranje Domena/Subdomene

**Opcija A: Jedan domen sa subdomenama (PREPORUČENO)**
```
frizerino.com         → Frontend (React)
api.frizerino.com     → Backend (Laravel API)
```

**Opcija B: Folderi na istom domenu**
```
frizerino.com         → Frontend
frizerino.com/api     → Backend (komplikovanije)
```

#### Kreiranje domena u Plesk-u:

1. **Websites & Domains** → **Add Domain**
2. Dodaj: `frizerino.com`
3. **Add Subdomain** → `api.frizerino.com`

### 3.3 PHP Konfiguracija za Backend

Za `api.frizerino.com`:

1. Klikni na domenu → **PHP Settings**
2. Postavi:
   - PHP Version: **8.2** ili novije
   - `memory_limit`: 256M
   - `max_execution_time`: 300
   - `upload_max_filesize`: 50M
   - `post_max_size`: 50M
   - `max_input_vars`: 3000

3. **PHP Extensions** - omogući:
   - ✅ pdo_pgsql
   - ✅ pgsql
   - ✅ redis
   - ✅ gd
   - ✅ mbstring
   - ✅ xml
   - ✅ curl
   - ✅ zip
   - ✅ bcmath
   - ✅ intl

---

## 4. Deployment Backend-a (Laravel)

### 4.1 Struktura Foldera na Serveru

```
/var/www/vhosts/frizerino.com/
├── api.frizerino.com/           ← Backend Laravel
│   ├── httpdocs/                ← Document root (public/)
│   └── laravel/                 ← Laravel aplikacija
└── frizerino.com/
    └── httpdocs/                ← Frontend (React build)
```

### 4.2 Git Deployment za Backend

1. U Plesk-u, idi na `api.frizerino.com` → **Git**
2. **Add Repository**:
   - Repository URL: `https://github.com/TVOJ_USERNAME/frizerino.git`
   - Deploy to: `/var/www/vhosts/frizerino.com/api.frizerino.com/laravel`

3. Postavi **Deployment Path**: `backend` (jer je Laravel u backend folderu)

### 4.3 SSH Konfiguracija za Backend

Povežite se na server preko SSH:

```bash
# Povežite se na server
ssh root@TVOJA_IP

# Prebaci se na korisnika domene
su - frizerino.com

# Idi u Laravel folder
cd /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend
```

### 4.4 Composer i Inicijalizacija

```bash
# Instaliraj composer dependencies
composer install --optimize-autoloader --no-dev

# Kopiraj .env fajl
cp .env.example .env

# Generiši APP_KEY
php artisan key:generate

# Kreiraj storage linkove
php artisan storage:link
```

### 4.5 .env Konfiguracija za Produkciju

Edituj `.env` fajl:

```bash
nano .env
```

```env
APP_NAME="Frizerino"
APP_ENV=production
APP_KEY=base64:GENERIRANO_GORE
APP_DEBUG=false
APP_URL=https://api.frizerino.com

# Frontend URL za CORS i emailove
FRONTEND_URL=https://frizerino.com

LOG_CHANNEL=stack
LOG_LEVEL=error

# PostgreSQL
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=frizerino
DB_USERNAME=frizerino_user
DB_PASSWORD=JAKA_LOZINKA_OVDJE

# Redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Cache i Session preko Redis-a
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Mail (Brevo/Sendinblue primjer)
MAIL_MAILER=smtp
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=tvoj_brevo_username
MAIL_PASSWORD=tvoj_brevo_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=info@frizerino.com
MAIL_FROM_NAME="Frizerino"

# Sanctum
SANCTUM_STATEFUL_DOMAINS=frizerino.com,www.frizerino.com
SESSION_DOMAIN=.frizerino.com
```

### 4.6 Document Root Konfiguracija

U Plesk-u za `api.frizerino.com`:

1. **Hosting Settings**
2. **Document Root**: `/var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/public`

### 4.7 Apache/Nginx Konfiguracija

U Plesk-u: `api.frizerino.com` → **Apache & nginx Settings**

**Additional nginx directives:**

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}

location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 4.8 Migracije i Finalna Podešavanja

```bash
# Pokreni migracije
php artisan migrate --force

# Seedaj bazu (ako treba)
php artisan db:seed --force

# Očisti i cache-iraj konfiguraciju
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Postavi permisije
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

---

## 5. Deployment Frontend-a (React)

### 5.1 Lokalni Build

Na svom računaru, prije pusha na GitHub:

```powershell
cd c:\Users\aleks\Desktop\FrizerskiSaloni\frontend

# Kreiraj production .env
```

Kreiraj `.env.production`:

```env
VITE_API_URL=https://api.frizerino.com
VITE_BASE_URL=https://frizerino.com
VITE_GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

```powershell
# Build za produkciju
npm run build
```

### 5.2 Deployment Opcije

#### Opcija A: Build lokalno, upload dist folder

1. Build-aj lokalno: `npm run build`
2. Upload-aj `dist/` folder na server u `/var/www/vhosts/frizerino.com/httpdocs/`

#### Opcija B: Build na serveru (PREPORUČENO)

1. U Plesk-u, idi na `frizerino.com` → **Git**
2. Clone cijeli repo
3. SSH na server:

```bash
cd /var/www/vhosts/frizerino.com/httpdocs/frontend

# Instaliraj dependencies
npm install

# Build
npm run build

# Kopiraj build u document root
cp -r dist/* ../
```

### 5.3 Nginx Konfiguracija za SPA

U Plesk-u: `frizerino.com` → **Apache & nginx Settings**

**Additional nginx directives:**

```nginx
location / {
    try_files $uri $uri/ /index.html;
}

# Proxy za sitemap (backend generiše)
location ~ ^/sitemap.*\.xml$ {
    proxy_pass https://api.frizerino.com;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

# Cache static assets
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## 6. Baza Podataka (PostgreSQL)

### 6.1 Instalacija PostgreSQL na Plesk-u

```bash
# SSH na server kao root
ssh root@TVOJA_IP

# Instaliraj PostgreSQL
apt update
apt install postgresql postgresql-contrib

# Pokreni PostgreSQL
systemctl enable postgresql
systemctl start postgresql
```

### 6.2 Kreiranje Baze i Korisnika

```bash
# Prebaci se na postgres korisnika
sudo -u postgres psql

# Kreiraj bazu
CREATE DATABASE frizerino;

# Kreiraj korisnika
CREATE USER frizerino_user WITH ENCRYPTED PASSWORD 'JAKA_LOZINKA_OVDJE';

# Dodijeli privilegije
GRANT ALL PRIVILEGES ON DATABASE frizerino TO frizerino_user;
ALTER DATABASE frizerino OWNER TO frizerino_user;

# Izađi
\q
```

### 6.3 Import Postojeće Baze (ako imaš)

Na lokalnom računaru exportuj bazu:

```powershell
pg_dump -U postgres -h localhost frizerinosalon > backup.sql
```

Na serveru importuj:

```bash
psql -U frizerino_user -d frizerino < backup.sql
```

---

## 7. Redis Instalacija i Konfiguracija

### 7.1 Instalacija Redis-a

```bash
# SSH kao root
ssh root@TVOJA_IP

# Instaliraj Redis
apt update
apt install redis-server

# Omogući Redis da se pokreće automatski
systemctl enable redis-server
systemctl start redis-server

# Provjeri status
systemctl status redis-server
```

### 7.2 Redis Konfiguracija

```bash
# Edituj konfiguraciju
nano /etc/redis/redis.conf
```

Promijeni:

```conf
# Bind na localhost (sigurnost)
bind 127.0.0.1

# Postavi maxmemory (npr. 256MB)
maxmemory 256mb
maxmemory-policy allkeys-lru

# Omogući persistence
appendonly yes
```

```bash
# Restartuj Redis
systemctl restart redis-server

# Testiraj
redis-cli ping
# Trebalo bi vratiti: PONG
```

### 7.3 PHP Redis Ekstenzija

```bash
# Instaliraj PHP Redis ekstenziju
apt install php8.2-redis

# Restartuj PHP-FPM
systemctl restart php8.2-fpm
```

---

## 8. Queue Worker (Supervisor)

Queue worker je **KRITIČAN** za:
- Slanje emailova (potvrda termina, otkazivanje, reset lozinke)
- Obavijesti
- Background procese

### 8.1 Instalacija Supervisor-a

```bash
# Instaliraj Supervisor
apt install supervisor

# Omogući automatsko pokretanje
systemctl enable supervisor
```

### 8.2 Kreiranje Queue Worker Konfiguracije

```bash
# Kreiraj konfiguraciju
nano /etc/supervisor/conf.d/frizerino-worker.conf
```

Dodaj:

```ini
[program:frizerino-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/storage/logs/worker.log
stopwaitsecs=3600
```

### 8.3 Pokretanje Queue Worker-a

```bash
# Učitaj novu konfiguraciju
supervisorctl reread
supervisorctl update

# Pokreni workere
supervisorctl start frizerino-worker:*

# Provjeri status
supervisorctl status
```

### 8.4 Korisne Supervisor Komande

```bash
# Restartuj workere (nakon deploymenta)
supervisorctl restart frizerino-worker:*

# Zaustavi workere
supervisorctl stop frizerino-worker:*

# Pogledaj logove
tail -f /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/storage/logs/worker.log
```

---

## 9. SSL Certifikati

### 9.1 Let's Encrypt preko Plesk-a

1. Za svaku domenu (`frizerino.com` i `api.frizerino.com`):
2. Idi na domenu → **SSL/TLS Certificates**
3. Klikni **Let's Encrypt**
4. Označi:
   - ✅ Secure the domain
   - ✅ Include www subdomain (za frizerino.com)
   - ✅ Redirect HTTP to HTTPS
5. Klikni **Get it Free**

### 9.2 Automatsko Obnavljanje

Plesk automatski obnavlja Let's Encrypt certifikate, ali provjeri:

1. **Tools & Settings** → **SSL/TLS Certificates**
2. Omogući automatsko obnavljanje

---

## 10. Cron Jobs

### 10.1 Laravel Scheduler

Laravel koristi jedan cron job koji pokreće scheduler:

U Plesk-u: **Tools & Settings** → **Scheduled Tasks (Cron)**

Dodaj task:

```
* * * * * cd /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend && php artisan schedule:run >> /dev/null 2>&1
```

### 10.2 Postojeći Scheduled Tasks

Tvoja aplikacija već ima:
- Slanje podsjetnika za termine (1 sat prije)
- Čišćenje starih notifikacija (30+ dana)
- Cache sitemap-a

Ovi će se automatski pokretati kad postaviš gornji cron.

---

## 11. Email Konfiguracija

### 11.1 Preporučeni Email Provideri

| Provider | Besplatno | Cijena |
|----------|-----------|--------|
| Brevo (Sendinblue) | 300/dan | Od €0 |
| Mailgun | 5,000/mjesec | Od $0 |
| Amazon SES | 62,000/mjesec (EC2) | $0.10/1000 |
| SMTP2GO | 1,000/mjesec | Od $0 |

### 11.2 Brevo Konfiguracija (Preporučeno)

1. Registriraj se na [brevo.com](https://www.brevo.com/)
2. Verifikuj domenu (DNS zapisi)
3. Dobij SMTP kredencijale

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=tvoj_email@domena.com
MAIL_PASSWORD=xsmtpsib-xxxxxxxx
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=info@frizerino.com
MAIL_FROM_NAME="Frizerino"
```

### 11.3 DNS Zapisi za Email

Dodaj ove DNS zapise za bolju dostavu emailova:

**SPF Record (TXT):**
```
v=spf1 include:spf.brevo.com ~all
```

**DKIM Record (TXT):**
```
Dobićeš od Brevo-a specifičan DKIM zapis
```

**DMARC Record (TXT):**
```
v=DMARC1; p=none; rua=mailto:dmarc@frizerino.com
```

---

## 12. Troubleshooting

### 12.1 Česti Problemi

#### "500 Internal Server Error" na API-ju

```bash
# Provjeri Laravel log
tail -f /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/storage/logs/laravel.log

# Provjeri permisije
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

#### Queue ne radi / Emailovi se ne šalju

```bash
# Provjeri supervisor status
supervisorctl status

# Restartuj workere
supervisorctl restart frizerino-worker:*

# Provjeri Redis
redis-cli ping

# Ručno procesiraj queue za test
php artisan queue:work --once
```

#### Frontend pokazuje blank stranicu

```bash
# Provjeri nginx logs
tail -f /var/log/nginx/frizerino.com-error.log

# Provjeri da li je build uspješan
ls -la /var/www/vhosts/frizerino.com/httpdocs/
```

#### CORS Greške

Provjeri da `.env` ima ispravno:
```env
FRONTEND_URL=https://frizerino.com
SANCTUM_STATEFUL_DOMAINS=frizerino.com,www.frizerino.com
SESSION_DOMAIN=.frizerino.com
```

### 12.2 Korisne Komande

```bash
# Laravel
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
php artisan optimize

# Redis
redis-cli FLUSHALL  # Briše sve (oprezno!)
redis-cli INFO      # Redis statistike

# Supervisor
supervisorctl status
supervisorctl tail frizerino-worker:frizerino-worker_00

# Logovi
tail -f /var/log/nginx/error.log
tail -f /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend/storage/logs/laravel.log
```

---

## 13. Deployment Checklist ✅

### Prije Go-Live:

- [ ] GitHub repo kreiran i kod pushovan
- [ ] Hetzner server pokrenut
- [ ] Plesk instaliran i konfiguriran
- [ ] PostgreSQL baza kreirana
- [ ] Redis instaliran i radi
- [ ] Backend deployovan i `.env` konfiguriran
- [ ] Frontend buildovan i deployovan
- [ ] SSL certifikati aktivirani
- [ ] Queue worker (Supervisor) radi
- [ ] Cron job za scheduler postavljen
- [ ] Email provider konfiguriran
- [ ] DNS zapisi postavljeni (A, CNAME, SPF, DKIM)
- [ ] Testiran signup/login
- [ ] Testirano slanje emailova
- [ ] Testirano kreiranje termina
- [ ] Sitemap dostupan na /sitemap.xml

### DNS Zapisi za Domenu:

```
TYPE    HOST                VALUE
A       @                   TVOJA_IP
A       api                 TVOJA_IP
A       www                 TVOJA_IP
CNAME   www                 frizerino.com
TXT     @                   v=spf1 include:spf.brevo.com ~all
```

---

## 14. Automatski Deployment (CI/CD) - Bonus

### GitHub Actions Workflow

Kreiraj `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend
            git pull origin main
            composer install --no-dev --optimize-autoloader
            php artisan migrate --force
            php artisan config:cache
            php artisan route:cache
            php artisan view:cache
            supervisorctl restart frizerino-worker:*
            
            cd /var/www/vhosts/frizerino.com/httpdocs/frontend
            git pull origin main
            npm install
            npm run build
            cp -r dist/* ../
```

---

## Kontakt za Podršku

Ako naiđeš na probleme:
1. Provjeri logove (Laravel, Nginx, Supervisor)
2. Google specifičnu grešku
3. Laravel dokumentacija: https://laravel.com/docs

Sretno s deploymentom! 🚀
