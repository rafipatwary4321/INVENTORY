# FIREBASE SETUP

This guide helps you connect INVENTORY to Firebase safely and correctly.

## Prerequisites

- Flutter SDK installed
- Firebase account
- Project cloned locally

## Step 1: Create Firebase Project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Analytics optionally (your preference)

## Step 2: Enable Services

### Authentication

- Go to **Authentication > Sign-in method**
- Enable **Email/Password**

### Firestore

- Create Firestore database
- Start with dev-friendly rules for local setup
- Harden rules before production release

### Storage

- Enable Firebase Storage
- Use strict production rules before going live

## Step 3: Configure FlutterFire

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Run configure in project root:

```bash
flutterfire configure
```

This generates/updates `lib/firebase_options.dart`.

## Step 4: Platform Files

Depending on targets, FlutterFire may ask for:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Follow FlutterFire output exactly.

## Step 5: Verify App Startup

Run:

```bash
flutter run -d chrome
```

Expected:

- Firebase-enabled startup if options are valid
- Demo fallback mode if Firebase is missing or invalid

## Step 6: Seed Initial Role Data

For role-based access, ensure each user profile has required fields in Firestore:

- `role` (`owner`, `admin`, `staff`)
- `businessId`
- `displayName`
- `isActive`

## Security Checklist

- Never commit real private credentials or service account keys
- Keep `.env` local and out of source control
- Use strict Firestore and Storage rules in production
- Rotate credentials if exposure is suspected

## Troubleshooting

### App runs in demo mode unexpectedly

- Check Firebase options in `lib/firebase_options.dart`
- Confirm keys are not placeholders (`YOUR_*`)
- Verify `flutterfire configure` completed for current platform

### Permission/auth issues

- Confirm Email/Password sign-in is enabled
- Check user profile document contains expected role fields

### Storage/image failures

- Review Storage rules
- Confirm authenticated user access and path permissions
