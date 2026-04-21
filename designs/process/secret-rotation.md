# Secret Rotation

Cadence for the credentials this repo depends on. A leaked or drifted token has a bounded blast radius if the rotation happens on a regular schedule and the schedule is written down where the release playbook can find it.

## Cadence

| Secret | Cadence | Next due |
| --- | --- | --- |
| `BUTLER_API_KEY` | Quarterly, first week of Jan, Apr, Jul, Oct | 2026-07 |

Quarterly is the baseline. Any secret with a stronger threat model (broader scope, automated access, or a history of exposure) gets a shorter cycle; note the rationale beside the cadence.

## How to rotate `BUTLER_API_KEY`

The butler token lets the `publish.yml` and `release.yml` workflows push to the itch.io channel. Rotation takes about five minutes.

1. Sign in to https://itch.io/user/settings/api-keys.
2. Generate a new API key labelled with the rotation date, for example `volley-ci-2026-07`.
3. Set the new value as the GitHub Actions secret: `gh secret set BUTLER_API_KEY --repo shuck-dev/volley`.
4. Revoke the previous key on itch.io.
5. Trigger a `publish.yml` run on `main` (empty push or workflow-dispatch) and confirm the butler step lands.
6. Note the rotation date in the table above, and bump "Next due" by three months.

## Adding a new secret to the schedule

When a workflow starts using a new credential, add a row here with the cadence, the rationale if it differs from the quarterly baseline, and the next due date. A secret that ships without a rotation entry is a secret that gets forgotten; the `supply-chain-scout` reviewer watches for this on workflow diffs.

## Related

- https://github.com/shuck-dev/volley/blob/main/SECURITY.md — disclosure window and contact.
- https://github.com/shuck-dev/volley/blob/main/.github/workflows/publish.yml — where `BUTLER_API_KEY` is consumed.
- https://github.com/shuck-dev/volley/blob/main/.github/workflows/release.yml — tagged-release publish path.
