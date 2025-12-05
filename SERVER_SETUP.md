# 🚀 Frizerino - Server Setup Uputstvo

## ✅ Završeno
- [x] GitHub repozitorij: https://github.com/aaleksandraa/frizerino.final.git
- [x] Kod pusovan na GitHub
- [x] Subdomena api.frizerino.com kreirana

---

## 📋 KORAK 1: Povezivanje na Server (SSH)

Otvori PowerShell ili terminal i poveži se na server:

```bash
ssh root@TVOJA_IP_ADRESA
```

Zamijeni `TVOJA_IP_ADRESA` sa stvarnom IP adresom servera.

---

## 📋 KORAK 2: Instalacija Potrebnih Paketa

### 2.1 Update sistema
```bash
apt update && apt upgrade -y
```

### 2.2 Instalacija PostgreSQL
```bash
apt install postgresql postgresql-contrib -y
systemctl enable postgresql
systemctl start postgresql
```

### 2.3 Instalacija Redis
```bash
apt install redis-server -y
systemctl enable redis-server
systemctl start redis-server

# Testiraj da radi
redis-cli ping
# Treba vratiti: PONG
```

### 2.4 Instalacija Supervisor-a (za queue workere)
```bash
apt install supervisor -y
systemctl enable supervisor
systemctl start supervisor
```

### 2.5 Instalacija Node.js (za frontend build)
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install nodejs -y

# Provjeri verziju
node --version
npm --version
```

---

## 📋 KORAK 3: Kreiranje PostgreSQL Baze

```bash
# Prebaci se na postgres korisnika
sudo -u postgres psql
```

U PostgreSQL shellu unesi:

```sql
-- Kreiraj bazu
CREATE DATABASE frizerino;

-- Kreiraj korisnika (PROMIJENI LOZINKU!)
CREATE USER frizerino_user WITH ENCRYPTED PASSWORD 'TvojaSuperJakaLozinka123!';

-- Dodijeli privilegije
GRANT ALL PRIVILEGES ON DATABASE frizerino TO frizerino_user;
ALTER DATABASE frizerino OWNER TO frizerino_user;

-- Dodaj potrebne privilegije za schema
\c frizerino
GRANT ALL ON SCHEMA public TO frizerino_user;

-- Izađi
\q
```

**⚠️ ZAPAMTI OVE PODATKE:**
- Database: `frizerino`
- Username: `frizerino_user`
- Password: `TvojaSuperJakaLozinka123!` (koristi svoju jaču lozinku!)

---

## 📋 KORAK 4: Konfiguracija u Plesk-u

### 4.1 PHP Podešavanja za api.frizerino.com

1. Uloguj se u Plesk
2. Idi na **Websites & Domains**
3. Klikni na **api.frizerino.com**
4. Klikni na **PHP Settings**
5. Postavi:
   - **PHP version**: 8.2 (ili novije)
   - `memory_limit`: **256M**
   - `max_execution_time`: **300**
   - `upload_max_filesize`: **50M**
   - `post_max_size`: **50M**
   - `max_input_vars`: **3000**

6. Klikni **Apply** ili **OK**

### 4.2 PHP Ekstenzije

U istom PHP Settings, idi na **Additional PHP Extensions** i omogući:
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

Klikni **Apply**.

---

## 📋 KORAK 5: Clone Backend na Server

### 5.1 Preko SSH (preporučeno)

```bash
# Idi u folder za api subdomen
cd /var/www/vhosts/frizerino.com/api.frizerino.com

# Kloniraj repozitorij
git clone https://github.com/aaleksandraa/frizerino.final.git temp_clone

# Premjesti backend folder
mv temp_clone/backend/* .
mv temp_clone/backend/.* . 2>/dev/null

# Obriši temp folder
rm -rf temp_clone

# Provjeri strukturu
ls -la
# Trebaš vidjeti: app, bootstrap, config, public, storage, artisan, composer.json itd.
```

### 5.2 Instalacija Composer Dependencies

```bash
# Instaliraj composer ako nije
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Instaliraj dependencies
cd /var/www/vhosts/frizerino.com/api.frizerino.com
composer install --optimize-autoloader --no-dev
```

---

## 📋 KORAK 6: Konfiguracija Laravel .env

### 6.1 Kreiraj .env fajl

```bash
cd /var/www/vhosts/frizerino.com/api.frizerino.com
cp .env.example .env
nano .env
```

### 6.2 Postavi vrijednosti u .env

Zamijeni CIJELI sadržaj sa ovim (prilagodi svoje vrijednosti):

```env
APP_NAME="Frizerino"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://api.frizerino.com

# Frontend URL - VAŽNO za CORS i emailove
FRONTEND_URL=https://frizerino.com

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US
APP_MAINTENANCE_DRIVER=file
PHP_CLI_SERVER_WORKERS=4
BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

# PostgreSQL - KORISTI SVOJE PODATKE!
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=frizerino
DB_USERNAME=frizerino_user
DB_PASSWORD=TvojaSuperJakaLozinka123!

# Session i Cookie
SESSION_DRIVER=redis
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=.frizerino.com
SESSION_SAME_SITE=lax
SESSION_SECURE_COOKIE=true

# Redis
REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Cache i Queue preko Redis-a
CACHE_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

# Sanctum - VAŽNO za auth!
SANCTUM_STATEFUL_DOMAINS=frizerino.com,www.frizerino.com,api.frizerino.com

# Mail - KORISTI BREVO (besplatno 300 emailova/dan)
MAIL_MAILER=smtp
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=tvoj_brevo_email
MAIL_PASSWORD=tvoj_brevo_smtp_key
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=info@frizerino.com
MAIL_FROM_NAME="Frizerino"
```

Snimi sa `Ctrl+X`, pa `Y`, pa `Enter`.

### 6.3 Generiši APP_KEY

```bash
php artisan key:generate
```

---

## 📋 KORAK 7: Podešavanje Laravel-a

### 7.1 Storage Link i Permisije

```bash
cd /var/www/vhosts/frizerino.com/api.frizerino.com

# Kreiraj storage link
php artisan storage:link

# Postavi permisije
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### 7.2 Migracije Baze

```bash
# Pokreni migracije
php artisan migrate --force

# Seedaj lokacije (gradovi BiH)
php artisan db:seed --class=LocationSeeder --force
```

### 7.3 Cache Konfiguraciju

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## 📋 KORAK 8: Document Root u Plesk-u

1. U Plesk-u idi na **api.frizerino.com**
2. Klikni **Hosting Settings**
3. Promijeni **Document Root** na:
   ```
   /var/www/vhosts/frizerino.com/api.frizerino.com/public
   ```
4. Klikni **OK**

---

## 📋 KORAK 9: Nginx Konfiguracija za API

U Plesk-u za **api.frizerino.com**:

1. Klikni **Apache & nginx Settings**
2. Pronađi **Additional nginx directives**
3. Dodaj:

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}

# Sitemap
location ~ ^/sitemap.*\.xml$ {
    try_files $uri $uri/ /index.php?$query_string;
}

# Cache static files
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

4. Klikni **OK**

---

## 📋 KORAK 10: Queue Worker (Supervisor)

### 10.1 Kreiraj Supervisor Konfiguraciju

```bash
nano /etc/supervisor/conf.d/frizerino-worker.conf
```

Dodaj:

```ini
[program:frizerino-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/vhosts/frizerino.com/api.frizerino.com/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/vhosts/frizerino.com/api.frizerino.com/storage/logs/worker.log
stopwaitsecs=3600
```

Snimi sa `Ctrl+X`, `Y`, `Enter`.

### 10.2 Pokreni Workere

```bash
supervisorctl reread
supervisorctl update
supervisorctl start frizerino-worker:*

# Provjeri status
supervisorctl status
```

Trebalo bi pokazati:
```
frizerino-worker:frizerino-worker_00   RUNNING
frizerino-worker:frizerino-worker_01   RUNNING
```

---

## 📋 KORAK 11: Cron Job za Laravel Scheduler

U Plesk-u:

1. Idi na **Tools & Settings** → **Scheduled Tasks**
2. Klikni **Add Task**
3. Postavi:
   - **Run**: `* * * * *` (svaku minutu)
   - **Command**:
   ```
   cd /var/www/vhosts/frizerino.com/api.frizerino.com && php artisan schedule:run >> /dev/null 2>&1
   ```
4. Klikni **OK**

---

## 📋 KORAK 12: Frontend Deployment

### 12.1 Na svom računaru - Build Frontend

```powershell
cd c:\Users\aleks\Desktop\FrizerskiSaloni\frontend

# Kreiraj production env
```

Kreiraj fajl `.env.production` sa sadržajem:

```env
VITE_API_URL=https://api.frizerino.com/api
VITE_BASE_URL=https://frizerino.com
```

```powershell
# Instaliraj dependencies i build-aj
npm install
npm run build
```

### 12.2 Upload dist folder na server

Imaš 2 opcije:

**Opcija A: Preko Plesk File Manager**
1. U Plesk-u idi na **frizerino.com** → **File Manager**
2. Idi u **httpdocs** folder
3. Obriši sve iz tog foldera
4. Upload-aj sadržaj iz `frontend/dist/` foldera

**Opcija B: Preko SFTP (FileZilla)**
1. Poveži se na server preko SFTP
2. Idi u `/var/www/vhosts/frizerino.com/httpdocs/`
3. Obriši sve
4. Upload-aj sadržaj iz `frontend/dist/` foldera

---

## 📋 KORAK 13: Nginx Konfiguracija za Frontend

U Plesk-u za **frizerino.com**:

1. Klikni **Apache & nginx Settings**
2. U **Additional nginx directives** dodaj:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}

# Proxy sitemap zahtjeve na backend
location ~ ^/sitemap.*\.xml$ {
    proxy_pass https://api.frizerino.com;
    proxy_set_header Host api.frizerino.com;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_ssl_verify off;
}

# Cache static assets
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

3. Klikni **OK**

---

## 📋 KORAK 14: SSL Certifikati (Let's Encrypt)

Za **obje** domene (frizerino.com i api.frizerino.com):

1. Klikni na domenu
2. Klikni **SSL/TLS Certificates**
3. Klikni **Let's Encrypt**
4. Označi:
   - ✅ Secure the domain
   - ✅ Include www subdomain (za frizerino.com)
   - ✅ Redirect HTTP to HTTPS
5. Klikni **Get it Free**

---

## 📋 KORAK 15: Email Konfiguracija (Brevo)

### 15.1 Registracija na Brevo

1. Idi na [brevo.com](https://www.brevo.com/)
2. Registriraj se (besplatno, 300 emailova/dan)
3. Verifikuj svoju email adresu

### 15.2 SMTP Kredencijali

1. U Brevo idi na **Transactional** → **Settings** → **SMTP & API**
2. Generiši SMTP ključ
3. Ažuriraj `.env` na serveru:

```bash
nano /var/www/vhosts/frizerino.com/api.frizerino.com/.env
```

Postavi:
```env
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=tvoj_email@domena.com
MAIL_PASSWORD=xsmtpsib-tvoj-api-kljuc
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=info@frizerino.com
MAIL_FROM_NAME="Frizerino"
```

### 15.3 Očisti Config Cache

```bash
cd /var/www/vhosts/frizerino.com/api.frizerino.com
php artisan config:cache
```

---

## 📋 KORAK 16: DNS Zapisi

U svom DNS provideru (ili Plesk-u) postavi:

| Tip | Naziv | Vrijednost |
|-----|-------|------------|
| A | @ | TVOJA_SERVER_IP |
| A | www | TVOJA_SERVER_IP |
| A | api | TVOJA_SERVER_IP |
| TXT | @ | v=spf1 include:spf.brevo.com ~all |

---

## 📋 KORAK 17: Testiranje

### 17.1 Testiraj API

U browseru otvori:
```
https://api.frizerino.com/api/v1/public/locations
```

Trebalo bi vratiti JSON sa gradovima.

### 17.2 Testiraj Frontend

Otvori:
```
https://frizerino.com
```

Trebala bi se prikazati početna stranica.

### 17.3 Testiraj Email

1. Idi na https://frizerino.com/registracija
2. Registriraj test korisnika
3. Provjeri da li email verifikacija stiže

### 17.4 Testiraj Sitemap

```
https://frizerino.com/sitemap.xml
```

---

## 🔧 Troubleshooting

### API vraća 500 Error

```bash
# Provjeri Laravel log
tail -f /var/www/vhosts/frizerino.com/api.frizerino.com/storage/logs/laravel.log

# Provjeri permisije
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Očisti cache
php artisan config:clear
php artisan cache:clear
```

### Emailovi se ne šalju

```bash
# Provjeri queue worker
supervisorctl status

# Restartuj workere
supervisorctl restart frizerino-worker:*

# Testiraj ručno
php artisan queue:work --once
```

### Frontend pokazuje blank stranicu

- Provjeri da li je `index.html` u httpdocs folderu
- Provjeri nginx konfiguraciju
- Provjeri konzolu u browseru (F12)

### CORS Greške

Provjeri u `.env`:
```env
FRONTEND_URL=https://frizerino.com
SANCTUM_STATEFUL_DOMAINS=frizerino.com,www.frizerino.com,api.frizerino.com
SESSION_DOMAIN=.frizerino.com
```

Pa očisti config cache:
```bash
php artisan config:cache
```

---

## ✅ Final Checklist

- [ ] PostgreSQL baza kreirana
- [ ] Redis radi (`redis-cli ping` vraća PONG)
- [ ] Backend kloniran i composer install završen
- [ ] .env konfiguriran sa ispravnim podacima
- [ ] Migracije pokrenute
- [ ] Document root postavljen na /public
- [ ] Supervisor queue worker radi
- [ ] Cron job za scheduler postavljen
- [ ] Frontend build-ovan i uploadovan
- [ ] SSL certifikati aktivni
- [ ] DNS zapisi postavljeni
- [ ] Email provider (Brevo) konfiguriran
- [ ] Testirana registracija
- [ ] Testirana prijava
- [ ] Testiran sitemap

---

## 🎉 Gotovo!

Tvoja aplikacija bi sada trebala biti dostupna na:
- **Frontend**: https://frizerino.com
- **API**: https://api.frizerino.com
- **Sitemap**: https://frizerino.com/sitemap.xml

Ako naiđeš na bilo kakve probleme, provjeri Laravel logove:
```bash
tail -f /var/www/vhosts/frizerino.com/api.frizerino.com/storage/logs/laravel.log
```
