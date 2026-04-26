# Contributing to INVENTORY

Thanks for contributing. This guide is designed to be clear for first-time open-source contributors.

## Start Here

Before opening issues or pull requests:

1. Read the [README](README.md)
2. Review [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
3. Read [SECURITY.md](SECURITY.md) for vulnerability reporting

## Ways to Contribute

### Report Bugs

Open a GitHub issue and include:

- App version or commit hash
- Flutter version (`flutter --version`)
- Platform/device (Android, iOS, Web/Chrome)
- Steps to reproduce
- Expected vs actual behavior
- Logs/screenshots if available

### Propose Features

Use a feature request issue and explain:

- The problem you are solving
- Who benefits
- Proposed behavior (optional implementation ideas)

### Improve Documentation

Docs contributions are welcome:

- Fix unclear instructions
- Add missing setup details
- Improve examples and screenshots

## Development Setup

```bash
git clone <your-fork-url>
cd INVENTORY
flutter pub get
```

Optional (for live backend mode): follow [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md).

## Branching and Pull Requests

1. Create a branch from `main`:
   ```bash
   git checkout -b feat/my-change
   ```
2. Keep changes focused and reviewable.
3. Run checks locally before pushing:
   ```bash
   flutter analyze
   flutter test
   ```
4. Push and open a PR with:
   - Summary of changes
   - Why the change is needed
   - Test evidence (commands/screenshots)

## Coding Guidelines

- Follow existing project style and folder conventions.
- Prefer reusable widgets and modular services/providers.
- Do not commit unrelated refactors in the same PR.
- Keep user-facing copy clear and concise.

## Security and Secrets

- Never commit real API keys, `.env`, service account JSON, or private credentials.
- Keep `.env` local; update `.env.example` when new variables are introduced.
- For security bugs, follow [SECURITY.md](SECURITY.md) instead of opening a public issue first.

## Commit Message Tips

Use short, clear messages in present tense:

- `Fix QR scan fallback on web`
- `Update Firebase setup docs`
- `Refactor report card spacing`

## Review and Merge Process

- Maintainers review PRs based on impact, clarity, and test coverage.
- You may be asked to make follow-up changes.
- After merge, notable changes should be reflected in [CHANGELOG.md](CHANGELOG.md).

Thanks again for helping improve INVENTORY.
