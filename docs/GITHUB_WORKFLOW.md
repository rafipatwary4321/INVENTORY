# GITHUB WORKFLOW

Recommended professional workflow for contributing to INVENTORY.

## Branch Strategy

- `main`: stable integration branch
- feature branches: short-lived, purpose-focused

Branch naming examples:

- `feat/premium-login-polish`
- `fix/qr-scan-web-fallback`
- `docs/firebase-setup-refresh`

## Standard Contribution Flow

1. Sync latest main
   ```bash
   git checkout main
   git pull
   ```
2. Create branch
   ```bash
   git checkout -b feat/my-change
   ```
3. Make focused changes
4. Run quality checks
   ```bash
   flutter analyze
   flutter test
   ```
5. Commit with clear message
6. Push branch and open pull request

## Pull Request Checklist

- [ ] Scope is focused and coherent
- [ ] No unrelated file churn
- [ ] Analyzer passes
- [ ] Tests pass (or rationale documented)
- [ ] README/docs updated if behavior changed
- [ ] Screenshots added for UI-heavy PRs (if useful)

## Commit Message Guidelines

Use clear and concise present-tense style:

- `Add restock insight empty state`
- `Fix dark mode contrast in report cards`
- `Update contributing guide for new workflow`

## Code Review Expectations

- Review for correctness, maintainability, and UX impact
- Request changes when checks or rationale are incomplete
- Keep feedback specific and respectful

## Suggested Repository Settings (Maintainers)

- Protect `main` branch
- Require PR review before merge
- Require status checks (`flutter analyze`, `flutter test`)
- Enable dependency alerts and security advisories

## Release Hygiene

- Keep `CHANGELOG.md` updated
- Tag stable releases using semantic versions
- Ensure release notes summarize user-facing changes
