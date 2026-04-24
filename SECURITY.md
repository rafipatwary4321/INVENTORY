# Security policy

## Supported versions

We aim to support the **latest published release** on the default branch. Older tags may not receive security fixes—upgrade when possible.

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a vulnerability

**Please do not** open a public GitHub issue for undisclosed security vulnerabilities.

Instead:

1. Use **GitHub Security Advisories** (“Report a vulnerability”) if the repository has private reporting enabled, **or**
2. Email the maintainers at a dedicated security address **if one is published in the repository or organization profile**, **or**
3. Open a **draft** issue with minimal detail and ask maintainers to contact you privately (only if no other channel exists).

Include:

- A short description of the issue and its impact
- Steps to reproduce (proof-of-concept if safe)
- Affected versions or commits (if known)
- Whether you believe the issue is already exploitable in production setups

We will try to acknowledge receipt within a reasonable time. Please allow maintainers time to patch before public disclosure.

## Scope (examples)

In scope for this project:

- Authentication bypass, insecure Firestore/Storage access patterns suggested by the app
- Client-side logic that could lead to inventory or financial abuse when combined with weak server rules
- Dependency vulnerabilities in shipped Flutter/Dart packages (report upstream too when appropriate)

Out of scope (examples):

- Issues that require physical access to an unlocked device
- Social engineering of end users
- Firebase misconfiguration **only** on a self-hosted project without a code defect (still worth documenting in discussions)

## Secure development reminders

- **Firestore and Storage rules** are your primary enforcement layer—never rely on the client alone.
- Rotate API keys and service accounts if they are ever exposed.
- Keep Flutter, Gradle, CocoaPods, and dependencies updated.

Thank you for helping keep users safe.
