# PROJECT OVERVIEW

## What is INVENTORY?

INVENTORY is a Flutter-based inventory and sales application designed for small businesses and teams.  
It combines stock tracking, QR operations, POS checkout, reports, and AI-assisted insights in one app.

## Project Goals

- Provide a clean, modern, and fast inventory workflow
- Support both Firebase-backed and demo/offline-friendly startup modes
- Keep role-based operations clear and safe (owner/admin/staff)
- Maintain a modular Flutter codebase that is easy to extend

## Core Modules

- Authentication and role resolution
- Product management (CRUD)
- QR generation and scanning workflows
- Stock-in and POS checkout operations
- Reporting and analytics
- AI assistant and insight screens
- Business/settings and appearance controls

## Architecture Snapshot

- **UI layer:** Screens + reusable premium widgets
- **State layer:** `provider` notifiers
- **Data/services:** Auth, product, sales, settings, storage, user services
- **Routing:** central named route generator
- **Configuration:** optional `.env` for AI providers

## Runtime Modes

### Firebase Mode

Uses Firebase Auth, Firestore, and Storage with real backend data.

### Demo Mode

Automatically enabled when Firebase is unavailable or not configured.
Useful for local testing and UI verification without cloud setup.

## Who Should Use This?

- Shop owners and small teams
- Developers building inventory/POS starters
- Contributors learning Flutter + Provider + Firebase patterns

## Next Reading

- [FEATURES.md](FEATURES.md)
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- [GITHUB_WORKFLOW.md](GITHUB_WORKFLOW.md)
