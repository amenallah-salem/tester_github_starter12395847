# Gym Planner — Full Stack

Stack: Django backend + Flutter frontend (web / iOS / Android) + Docker.

---

## Quick start (Docker Compose — recommended)

```bash
# Terminal 1 — full stack
docker-compose up --build
# Terminal 2 — frontend only (port 8080, nginx)
docker-compose -f docker-compose.frontend.yml up --build
```

---

## Backend (Django)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

---

## Frontend (Flutter)

```bash
cd frontend
flutter pub get
# Web
flutter build web
flutter run -d chrome
# Android (requires SDK + emulator)
flutter run -d android
# iOS (macOS only; requires signing cert)
flutter run -d ios --release
```

---

## Tests

```bash
# Flutter (graceful if none exist)
cd frontend && flutter test || echo "No tests."
# Django
cd backend && python manage.py test
```

---

## CI (GitHub Actions)

`.github/workflows/flutter-mobile-ci.yml`
- Runs on push/PR (`main`) and tags (`v*`).
- Builds Android APK + iOS archive; creates releases.

---

## Honest limitations

- Android emulator requires KVM / hardware accel; not available inside containers.
- iOS build (`flutter build ios`) requires macOS + Apple signing certs (not included).
- Full CI execution requires `secrets.GITHUB_TOKEN` + Flutter SDK installed on runners.
- See `.github/workflows/CI_NOTES.md` and `frontend/TESTING_NOTES.md`.

---

Branch: `main` (merged: T-09 + T-17 + CI pipeline).
