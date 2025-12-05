#!/bin/bash

# =============================================
# Frizerino Deployment Script
# Run this on the server after git pull
# =============================================

set -e  # Exit on any error

echo "🚀 Starting Frizerino Deployment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
BACKEND_PATH="/var/www/vhosts/frizerino.com/api.frizerino.com/laravel/backend"
FRONTEND_PATH="/var/www/vhosts/frizerino.com/httpdocs"
FRONTEND_SOURCE="/var/www/vhosts/frizerino.com/frontend-source/frontend"

# =============================================
# Backend Deployment
# =============================================
echo -e "${YELLOW}📦 Deploying Backend...${NC}"

cd $BACKEND_PATH

# Pull latest changes
echo "Pulling latest code..."
git pull origin main

# Install dependencies
echo "Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader --no-interaction

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Clear and cache
echo "Optimizing Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Clear sitemap cache
echo "Clearing sitemap cache..."
php artisan sitemap:clear

# Fix permissions
echo "Setting permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Restart queue workers
echo "Restarting queue workers..."
supervisorctl restart frizerino-worker:*

echo -e "${GREEN}✅ Backend deployment complete!${NC}"

# =============================================
# Frontend Deployment
# =============================================
echo -e "${YELLOW}📦 Deploying Frontend...${NC}"

cd $FRONTEND_SOURCE

# Pull latest changes
echo "Pulling latest code..."
git pull origin main

# Install dependencies
echo "Installing npm dependencies..."
npm install

# Build for production
echo "Building frontend..."
npm run build

# Copy to public folder
echo "Copying build to document root..."
rm -rf $FRONTEND_PATH/*
cp -r dist/* $FRONTEND_PATH/

echo -e "${GREEN}✅ Frontend deployment complete!${NC}"

# =============================================
# Final Steps
# =============================================
echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo "Checklist:"
echo "  - [ ] Test homepage: https://frizerino.com"
echo "  - [ ] Test API: https://api.frizerino.com/api/v1/health"
echo "  - [ ] Test login/signup"
echo "  - [ ] Test booking flow"
echo "  - [ ] Check sitemap: https://frizerino.com/sitemap.xml"
