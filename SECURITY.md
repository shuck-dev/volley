# Security policy

Volley! is developed in the open. If you find a security issue in the code, the build pipeline, or the CI that ships releases, this page is how to get it to us.

## Scope

In scope:

- The Volley! game code in this repository.
- The GitHub Actions workflows in [`.github/workflows/`](.github/workflows/).
- The build and release pipeline that produces itch.io uploads.

Out of scope:

- Design documents in [`designs/`](designs/) and other written content.
- Third-party services the project links to (itch.io, GitHub, Linear). Report those to the vendors directly.
- Bugs that are not security issues. File those as regular issues on GitHub.

## Reporting a vulnerability

Email `security@shuck.games` with the details: what the issue is, how to reproduce it, and any impact you have already worked out. If that address bounces, fall back to Josh's public address from this repo's git history (`josh@hartley.best`) and note the bounce in your message.

Please do not open a public GitHub issue for security reports. A private channel gives us time to understand the issue and ship a fix before it is visible to everyone.

## What to expect

- **Acknowledgement within five business days.** A human replies to confirm the report has landed and name a point of contact.
- **Ninety-day disclosure window.** We aim to have a fix shipped, or a clear plan communicated to you, within ninety days of the acknowledgement. If we need longer, we will say so and explain why.
- **Credit on request.** If you would like to be named in the release notes for the fix, say so in your report and tell us how you would like to be credited.

## Safe harbour

Good-faith security research on Volley! is welcome. If you follow this policy, act in good faith, avoid privacy violations and service disruption, and give us a reasonable chance to fix the issue before public disclosure, we will not pursue legal action for your research. This applies to the scope listed above.

If you are unsure whether something is in scope or whether a given technique is acceptable, email first and ask. We would rather answer a question than receive a report we cannot accept.
