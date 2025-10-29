# Employee System

A Flutter app to manage employees with Firebase backend (Auth + Firestore).

This repository contains the mobile app source and a basic CI workflow.

## Getting started

Prerequisites:
- Flutter SDK (stable)
- Dart
- Android SDK / Xcode if building native targets

Clone the repo and install dependencies:

```powershell
git clone https://github.com/ShivamKGupta995/employee-management.git
cd employee-management
flutter pub get
```

## Firebase configuration

This project uses Firebase. Local platform config files are intentionally not tracked.

1. Create a Firebase project and add Android/iOS apps.
2. Download `google-services.json` for Android and place it at `android/app/google-services.json`.
3. Download `GoogleService-Info.plist` for iOS and place it at `ios/Runner/GoogleService-Info.plist`.

If you need a template for local environment variables, add a `.env.sample` and never commit real `.env` files.

Note: The repository's `.gitignore` already excludes these files. If you accidentally committed secrets, contact me and I can help remove them from git history safely.

## Running the app

Run on an attached device or emulator:

```powershell
flutter run
```

To build APK or iOS:

```powershell
flutter build apk --release
flutter build ios --release
```

## Tests & Analyzer

Run analyzer and tests locally:

```powershell
flutter analyze
flutter test
```

CI is configured with GitHub Actions in `.github/workflows/flutter.yml` to run `flutter analyze` and `flutter test` on pushes and PRs to `main`.

## Versioning & Releases

This repo uses git tags for releases. Example (local):

```powershell
git tag -a v1.0.0 -m "v1.0.0"
git push origin --tags
```

We already pushed `v1.0.0` in this repository.

## Recommended improvements

- Create users server-side (Cloud Function or Admin SDK) to avoid client-side auth switching when creating new users.
- Add automated tests for the admin flows.
- Add upload of coverage reports in CI.

## Troubleshooting

- If you see `Error loading employees` after adding a user: this can happen when the client briefly signs out during user creation. A server-side user creation avoids this.
- If you accidentally committed secret files and need them fully removed from history, we can use `git filter-repo` or BFG to scrub them (requires force-push and coordination).

## Contact

If you want more help (CI improvements, removing secrets, or migrating user creation to a Cloud Function), tell me which item to do next and I'll implement it.
# employee_system

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
