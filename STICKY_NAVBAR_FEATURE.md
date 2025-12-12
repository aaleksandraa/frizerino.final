# Sticky Navbar Feature

## Opis
Dodana je opcija u admin panelu koja omogućava uključivanje/isključivanje sticky (fiksiranog) navigacionog menija pri skrolovanju stranice.

## Šta je urađeno

### Backend
1. **SettingsController.php**
   - Dodana metoda `updateStickyNavbar()` za čuvanje sticky navbar postavke
   - Ažurirana metoda `getAppearance()` da vraća `sticky_navbar` opciju

2. **Routes (api.php)**
   - Dodana ruta `PUT /admin/sticky-navbar` za admin i owner role

3. **Migracija**
   - Kreirana migracija koja dodaje `sticky_navbar` setting u `system_settings` tabelu
   - Default vrednost: `true` (uključeno)

### Frontend

1. **AppearanceContext.tsx**
   - Dodat `stickyNavbar` state u context
   - Učitavanje sticky navbar opcije iz API-ja

2. **MainNavbar.tsx**
   - Ažurirana logika za primenu sticky/fixed pozicioniranja
   - Navbar se ponaša prema `stickyNavbar` opciji:
     - Ako je `true`: navbar je sticky/fixed (ostaje na vrhu pri skrolovanju)
     - Ako je `false`: navbar je statičan (skroluje se sa stranicom)

3. **AdminSettings.tsx**
   - Dodat UI u "Appearance" tabu za kontrolu sticky navbar opcije
   - Toggle switch za uključivanje/isključivanje
   - Čuvanje postavke zajedno sa ostalim appearance settings

4. **API Service (api.ts)**
   - Dodane metode:
     - `getAppearanceSettings()` - učitavanje appearance settings
     - `updateStickyNavbar(sticky: boolean)` - čuvanje sticky navbar opcije

## Kako koristiti

### Admin panel
1. Ulogujte se kao admin
2. Idite na **Settings** → **Appearance** tab
3. Skrolujte do sekcije **"Navigacija"**
4. Uključite/isključite opciju **"Fiksiran meni pri skrolovanju"**
5. Kliknite **"Sačuvaj postavke izgleda"**
6. Osvježite stranicu da vidite promjene

### Ponašanje
- **Uključeno (default)**: Navbar ostaje na vrhu ekrana pri skrolovanju
- **Isključeno**: Navbar se skroluje zajedno sa sadržajem stranice

## Tehnički detalji

### CSS klase
- **Sticky mode**: `sticky top-0` ili `fixed top-0`
- **Static mode**: bez sticky/fixed klasa

### Responsive
- Opcija radi na svim uređajima (desktop, tablet, mobile)
- Na transparent stranicama (homepage) navbar prelazi iz transparent u gradient pri skrolovanju (ako je sticky uključen)

## API Endpoints

### GET /public/appearance-settings
Vraća sve appearance settings uključujući `sticky_navbar`

**Response:**
```json
{
  "gradient": {...},
  "navbar_gradient": {...},
  "hero_background_image": "...",
  "salon_profile_layout": "classic",
  "sticky_navbar": true
}
```

### PUT /admin/sticky-navbar
Čuva sticky navbar opciju

**Request:**
```json
{
  "sticky": true
}
```

**Response:**
```json
{
  "message": "Sticky navbar postavka je uspješno sačuvana",
  "sticky_navbar": true
}
```

## Testiranje
1. Uključite sticky navbar u admin panelu
2. Skrolujte stranicu - navbar treba da ostane na vrhu
3. Isključite sticky navbar
4. Skrolujte stranicu - navbar treba da se skroluje sa sadržajem
