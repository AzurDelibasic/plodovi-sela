# Plodovi sela

Flutter aplikacija — tržnica gdje ljudi sa sela objavljuju svoje domaće
namirnice (voće, povrće, mliječni proizvodi...), a kupci ih pronalaze i
kupuju. Backend je Supabase (Postgres + Auth + Storage).

## Stack

- Flutter 3.35 / Dart 3.9 (stable)
- `supabase_flutter` — auth, baza, storage
- `flutter_riverpod` — state management i dependency injection
- `go_router` — navigacija, sa redirect logikom vezanom za auth sesiju
- `fpdart` (`Either<Failure, T>`) — eksplicitno rukovanje greškama bez
  bacanja izuzetaka do UI sloja
- `freezed` / `json_serializable` — dostupni za imutabilne modele kad
  zatrebaju (npr. za listinge namirnica)
- `flutter_dotenv` — konfiguracija preko `.env` fajla (nije u git-u)

## Arhitektura

Feature-first, sa slojevima po Clean Architecture principu unutar svakog
feature-a:

```
lib/
  core/                     # zajedničko: config, theme, router, error, supabase klijent
  features/
    auth/
      domain/               # entiteti, repository interfejs, use case-ovi (bez Flutter/Supabase importa)
      data/                 # datasource (Supabase pozivi), modeli, repository implementacija
      presentation/         # Riverpod provideri, ekrani, widgeti
    listings/                # oglasi namirnica (sledeći korak)
    profile/                  # profil korisnika (sledeći korak)
```

Pravilo zavisnosti: `presentation` zavisi od `domain`, `data` zavisi od
`domain`, a `domain` ne zna ni za Flutter ni za Supabase. Repository
interfejs je definisan u `domain`, implementiran u `data`. Time se npr.
Supabase može zamijeniti drugim backendom bez diranja UI-ja ili poslovne
logike.

## Setup

1. Instaliraj zavisnosti:

   ```bash
   flutter pub get
   ```

2. Kopiraj `.env.example` u `.env` i popuni sa podacima iz tvog Supabase
   projekta (Project Settings → Data API → Project URL / anon key):

   ```bash
   cp .env.example .env
   ```

3. Pokreni app:

   ```bash
   flutter run
   ```

## Trenutno stanje

- [x] Arhitektura i folder struktura
- [x] Supabase inicijalizacija preko `.env`
- [x] Auth feature: prijava (login), `AuthRepository`, use case-ovi,
      Riverpod provideri
- [x] Router sa redirect logikom (neprijavljen → `/login`, prijavljen → `/`)
- [x] Placeholder home ekran nakon prijave
- [ ] Registracija korisnika (kupac vs. prodavac)
- [ ] Feature `listings`: šema baze, objavljivanje/pregled namirnica
- [ ] Profil korisnika, slike proizvoda (Supabase Storage)
- [ ] Narudžbe / kontakt kupac-prodavac

## Napomena o bazi

Baza (šema, tabele) još nije definisana — pravi se u zasebnom Supabase
projektu ("plodoviSela"). Kad šema bude spremna, `listings` feature (data
sloj) se puni po istom obrascu kao `auth`: datasource → repository → use
case → provider → ekran.
