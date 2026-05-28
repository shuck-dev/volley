# Bot identity: shuck-volley-bot

The swarm's automated actions on this repo run under a GitHub App, `shuck-volley-bot[bot]`, so agent-driven reviews are attributed to a distinct identity in the Reviews tab rather than appearing as the maintainer's own actions.

## Account

- **Type:** GitHub App, owned by the `shuck-dev` org.
- **App ID:** stored in the `BOT_APP_ID` repo secret.
- **Private key:** stored in the `BOT_APP_PRIVATE_KEY` repo secret. No local copy is kept; tokens are minted inside workflows.
- **Installation:** installed on `shuck-dev`, scoped to this repo only.

## Scope

Repository permissions: Pull requests (read/write), Checks (read/write), Contents (read), Metadata (read). No organisation or account permissions. The App cannot be added as a requested reviewer (GitHub Apps are not requestable); it posts reviews via the API.

## Token handling

Workflows mint a short-lived installation token (five minutes) from the App ID and private key at run time, scoped to this repo. The token is never persisted. The bot cannot approve a PR it authored, so it is the reviewer identity, not the PR author.

## Rotation

To rotate the private key: generate a new key in the App settings (Organization settings, Developer settings, GitHub Apps, shuck-volley-bot, Private keys), update the `BOT_APP_PRIVATE_KEY` secret, then revoke the old key. The App ID does not change.
