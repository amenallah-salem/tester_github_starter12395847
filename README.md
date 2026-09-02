# Gym Planner — Ready to Go / Ready to Monetize

Status: production-scaffold with CI (GitHub Actions), mobile builds (Android APK + iOS archive), auth + billing stub.

## Earn money with this
- Subscriptions: `frontend/lib/services/api_client.dart` → `/billing/subscription`; backend stub at `backend/gym_api/billing.py`
- Lock features behind `checkSubscription()`; upgrade with `upgradeSubscription('premium')`
- Add Stripe webhook endpoint to `backend/`; put fee logic in `SubscriptionViewSet`

## Deploy
- Docker: `docker-compose up --build` (port 80 / 8080 mapped)
- Mobile releases: CI publishes prerelease on every `push` to `main` + tag `v*`
- Signing: see `frontend/signing-reference.md` + `key.properties.example`

## Verification (this session)
- CI rebuilt from `amenallah-salem/gym_app_starter_2548596354` reference (flutter-actions/setup-flutter@v4, upload-artifact@v4, prerelease)
- Push confirmed (`f6f921a` → `main`, 0 unpushed)
- Ad-hoc scripts run and cleaned (`hermes-*` temp, exit 0)
- Honest limits: no SDK/macOS/keystore in this env; no actual `flutter build` executed; release artifacts unsigned; billing is stub only

Branch: `main` (merged T-09 + T-17 + CI + improvements).
