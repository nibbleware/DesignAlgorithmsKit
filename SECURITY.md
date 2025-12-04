# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

> **Note**: This project is currently internal-only. Security vulnerabilities should be reported internally through appropriate channels.

For internal team members, please report (suspected) security vulnerabilities to the project maintainers through internal security channels. You will receive a response within 48 hours. If the issue is confirmed, we will release a patch as soon as possible depending on complexity.

### Reporting Process

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email security@rickhohler.com with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)
3. We will acknowledge receipt within 48 hours
4. We will provide an estimated timeline for a fix
5. Once fixed, we will:
   - Release a security patch
   - Credit you in the security advisory (unless you prefer to remain anonymous)
   - Update the CHANGELOG.md

## Security Best Practices

When using DesignAlgorithmsKit:

- **Hash Algorithms**: The SHA-256 implementation uses CryptoKit when available. For production use, ensure you're using a platform that supports CryptoKit or provide a secure alternative.
- **Bloom Filters**: Be aware that Bloom Filters have false positives. Do not use them for security-critical membership checks without additional verification.
- **Merkle Trees**: Ensure proper verification of Merkle proofs in security-sensitive contexts.
- **Thread Safety**: All patterns are designed to be thread-safe, but always review your specific use case.

## Disclosure Policy

- Security vulnerabilities will be disclosed publicly after a patch is released
- We will credit the reporter (unless they prefer anonymity)
- Critical vulnerabilities will be disclosed immediately after patching
- Non-critical vulnerabilities will be included in the next regular release

Thank you for helping keep DesignAlgorithmsKit and its users safe!

