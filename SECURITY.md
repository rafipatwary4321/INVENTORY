# Security Policy

## Supported Versions

Security fixes are prioritized for the latest active release branch.

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

Please do **not** open a public issue for undisclosed security vulnerabilities.

Preferred reporting order:

1. Use GitHub Security Advisories ("Report a vulnerability") if enabled.
2. If advisories are unavailable, contact maintainers privately via published repository/org channel.
3. Only if private channels are unavailable, open a minimal draft issue requesting secure contact.

Include the following:

- Vulnerability summary and impact
- Reproduction steps (safe proof of concept)
- Affected area/version/commit
- Suggested mitigation (if known)

We aim to acknowledge reports promptly and coordinate responsible disclosure.

## Security Scope

Examples in scope:

- Authentication and authorization bypass
- Business/tenant isolation issues in role or data access logic
- Unsafe Firestore/Storage access patterns caused by code guidance
- Secret leakage in repository, build config, or documentation
- High-impact dependency vulnerabilities affecting shipped behavior

Examples typically out of scope:

- Device compromise requiring local physical access
- Social engineering unrelated to code vulnerabilities
- Misconfigured third-party deployment with no project code defect

## Security Best Practices for This Project

- Treat `.env` and API keys as sensitive; never commit them.
- Keep Firebase rules strict; do not rely only on client checks.
- Rotate credentials immediately if exposure is suspected.
- Keep Flutter SDK and dependencies updated.
- Review AI provider usage and restrict key scopes where possible.

## Disclosure Policy

Please allow maintainers time to investigate and patch before public disclosure.
Coordinated disclosure helps protect all users and integrators.
