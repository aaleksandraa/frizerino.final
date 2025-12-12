# Sortiranje salona - Ispravka

## Problem
Sortiranje salona nije radilo pravilno - saloni nisu bili sortirani po ocjeni, broju recenzija, nazivu i udaljenosti kako treba.

## Šta je popravljeno

### 1. Logika sortiranja (sortSalons funkcija)

**Prije:**
- Sortiranje je bilo obrnuto - desc je vraćao manje vrednosti prvo
- Komplikovana logika sa različitim pravilima za različite tipove

**Poslije:**
- Jednostavna i konzistentna logika:
  - `asc` (ascending): od manjeg ka većem (A-Z, 1-10, bliže-dalje)
  - `desc` (descending): od većeg ka manjem (Z-A, 10-1, dalje-bliže)

### 2. Default sortDirection za svaki tip

**Ocjena (rating):**
- Default: `desc` (najviša ocjena prvo)
- Primer: 5.0 → 4.5 → 4.0 → 3.5

**Broj recenzija (reviews):**
- Default: `desc` (najviše recenzija prvo)
- Primer: 100 → 50 → 20 → 5

**Naziv (name):**
- Default: `asc` (alfabetski A-Z)
- Primer: Salon A → Salon B → Salon C
- Koristi hrvatski locale za pravilno sortiranje (č, ć, š, ž, đ)

**Udaljenost (distance):**
- Default: `asc` (najbliži prvo)
- Primer: 0.5 km → 1.2 km → 3.5 km → 10 km

### 3. UI poboljšanja

**Sort dugme:**
- Prikazuje trenutni tip sortiranja i smer
- Primer: "Ocjena ↓" ili "Naziv ↑"
- Na mobilnim uređajima prikazuje samo "Sortiraj"

**Sort dropdown:**
- Klik na isti tip menja smer (asc ↔ desc)
- Klik na drugi tip postavlja default smer za taj tip
- Vizuelna indikacija trenutnog sortiranja (pink pozadina)
- Strelica pokazuje smer (↓ desc, ↑ asc)

## Kako radi

### Sortiranje po ocjeni (desc - default)
```
Salon A (5.0) ← Prikazuje se prvi
Salon B (4.5)
Salon C (4.0)
Salon D (3.5)
```

### Sortiranje po broju recenzija (desc - default)
```
Salon A (150 recenzija) ← Prikazuje se prvi
Salon B (80 recenzija)
Salon C (25 recenzija)
Salon D (5 recenzija)
```

### Sortiranje po nazivu (asc - default)
```
Salon Anđela ← Prikazuje se prvi
Salon Beauty
Salon Čarolija
Salon Šarm
```

### Sortiranje po udaljenosti (asc - default)
```
Salon A (0.3 km) ← Prikazuje se prvi (najbliži)
Salon B (1.5 km)
Salon C (3.2 km)
Salon D (8.5 km)
```

## Tehnički detalji

### sortSalons funkcija
```typescript
const sortSalons = useCallback((salonsToSort: Salon[]): Salon[] => {
  return [...salonsToSort].sort((a, b) => {
    let comparison = 0;
    
    switch (sortBy) {
      case 'rating':
        comparison = (a.rating || 0) - (b.rating || 0);
        break;
      case 'reviews':
        comparison = (a.reviews_count || 0) - (b.reviews_count || 0);
        break;
      case 'name':
        comparison = a.name.localeCompare(b.name, 'hr');
        break;
      case 'distance':
        comparison = (distA) - (distB);
        break;
    }
    
    // desc: -comparison (obrće redosled)
    // asc: comparison (zadržava redosled)
    return sortDirection === 'desc' ? -comparison : comparison;
  });
}, [sortBy, sortDirection, userLocation]);
```

### Default direction logika
```typescript
if (option.value === 'distance' || option.value === 'name') {
  setSortDirection('asc');  // Bliže prvo, A-Z
} else {
  setSortDirection('desc'); // Više prvo, bolje prvo
}
```

## Testiranje

1. **Ocjena:**
   - Kliknite "Sortiraj" → "Ocjena"
   - Trebaju se prikazati saloni sa najvišom ocjenom prvo
   - Kliknite ponovo da promenite smer (najniža prvo)

2. **Broj recenzija:**
   - Kliknite "Sortiraj" → "Broj recenzija"
   - Trebaju se prikazati saloni sa najviše recenzija prvo
   - Kliknite ponovo da promenite smer (najmanje prvo)

3. **Naziv:**
   - Kliknite "Sortiraj" → "Naziv"
   - Trebaju se prikazati saloni alfabetski A-Z
   - Kliknite ponovo da promenite smer (Z-A)

4. **Udaljenost:**
   - Kliknite "Blizu mene" (omogućite lokaciju)
   - Automatski se sortira po udaljenosti (najbliži prvo)
   - Ili kliknite "Sortiraj" → "Udaljenost"
   - Kliknite ponovo da promenite smer (najdalji prvo)

## Napomene

- Hrvatski locale (`'hr'`) se koristi za pravilno sortiranje specijalnih karaktera
- Udaljenost se računa samo ako je korisnik omogućio lokaciju
- Saloni bez ocjene se tretiraju kao 0
- Saloni bez recenzija se tretiraju kao 0
- Saloni bez lokacije se tretiraju kao beskonačno daleki (Infinity)
