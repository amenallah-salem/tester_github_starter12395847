# Flutter Emulator / Test Limitation Note (T-17)

REAL LIMITATIONS (honest):
- This Dockerfile builds a Flutter WEB artifact (`flutter build web`), not an Android APK.
- Real Android emulator requires KVM / hardware acceleration (`/dev/kvm`, nested virtualization) and a display / Android SDK. It is NOT available inside this container.
- The `docker-compose.frontend.yml` serves the compiled web build on port 8080 (`nginx`) only.
- For mobile testing: run `flutter run -d android` or `flutter run -d ios` locally with an emulator / physical device; Docker is for web validation only.
- Web rendering uses `html` renderer (`FLUTTER_WEB_RENDERER=html`) for broader compatibility.

BUILD / TEST COMMANDS:
- Web build (Docker): `docker-compose -f docker-compose.frontend.yml up --build`
- Web local: `flutter build web` then `python3 -m http.server 8080 -d build/web`
- Android emulator (local, requires SDK + KVM): `flutter emulators --launch <id>` then `flutter run`
