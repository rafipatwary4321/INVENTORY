# Contributing to INVENTORY

Thank you for helping improve this project. This guide is written for contributors who may be new to Flutter or open source.

## Before you start

1. Read the [README](README.md) and [Code of Conduct](CODE_OF_CONDUCT.md).
2. For security-sensitive issues, use [SECURITY.md](SECURITY.md) instead of a public issue.

## How to contribute

### Report a bug

Use **Bug report** in GitHub Issues and include:

- Flutter version (`flutter --version`)
- Device/OS (or emulator)
- Steps to reproduce
- What you expected vs what happened

### Suggest a feature

Use **Feature request** and describe the problem you are solving, not only the solution you imagine.

### Submit a pull request

1. **Fork** the repository and create a branch from `main` (or the default branch).
2. **Keep changes focused**—one logical change per PR is easier to review.
3. **Run checks locally:**
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```
4. **Formatting:** follow existing style; run `dart format .` if you change Dart files.
5. **Commit messages:** use clear, present-tense summaries (e.g. `Fix cart stock validation`).
6. Open a PR and fill in the **pull request template**.

## Project conventions

- **State:** `provider`—prefer small, focused providers/notifiers.
- **Firebase:** do not commit real `google-services.json` / `GoogleService-Info.plist` to a **public** repo if they embed secrets; use placeholders or CI secrets.
- **i18n / currency:** this app targets **BDT**; keep formatting consistent with `lib/core/utils/bdt_formatter.dart`.

## What happens after you open a PR

Maintainers will review when they can. You may be asked for small follow-ups—that is normal. Once approved, your contribution will be merged and listed in the [CHANGELOG](CHANGELOG.md).

Thank you again for contributing.
