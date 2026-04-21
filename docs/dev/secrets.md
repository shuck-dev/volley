# Developer secrets: keep them off disk, off world-read

This is the short version of how personal API keys live on a Volley! developer machine. It covers the files that tend to accumulate credentials (`~/.claude/settings.json`, shell rc files, environment helpers) and the migration path to a password manager so those credentials stop sitting unencrypted in the home directory.

The rule in one line: secrets belong in a manager that prompts for unlock, not in a world-readable file.

## What counts as a secret here

- Linear API keys (`LINEAR_API_KEY`).
- Anthropic API keys used by Claude Code (`ANTHROPIC_API_KEY`).
- GodotIQ tokens and other MCP server credentials.
- GitHub personal access tokens used outside of `gh auth`.
- itch.io API keys used by butler.

Anything the project needs to call a third-party service on your behalf belongs on this list. Tokens that only exist inside `gh auth` or `op signin` are already managed; leave those alone.

## Baseline: tighten file modes

The one concrete change every dev machine needs is a stricter mode on the Claude settings file, which ships as `644` by default and ends up holding MCP env blocks:

```sh
chmod 600 ~/.claude/settings.json
chmod 600 ~/.claude/settings.local.json  # if present
```

Same treatment for anything else in the home directory that holds plaintext credentials:

```sh
chmod 600 ~/.netrc ~/.pypirc ~/.npmrc ~/.config/gh/hosts.yml 2>/dev/null
# audit every world-readable file under ~/.config, including .yml, .toml, .env, and dotfiles
find ~/.config -type f -perm /044 -print
find ~ -maxdepth 2 -type f -name '.*' -perm /044 -print  # also sweep home-dir dotfiles
```

If a file needs to stay world-readable (a checked-in sample config, a public key), it should not contain a secret in the first place. Move the secret out, then relax the mode.

## Migration path: move secrets into a manager

Pick one of these and stick with it. Both are fine; the choice is about workflow preference.

### Option A: `pass` (gpg-backed, filesystem store)

`pass` encrypts each secret as a `.gpg` file under `~/.password-store/`. Unlock with the gpg agent, read with a single command.

```sh
# one-time setup
sudo pacman -S pass                     # or: brew install pass
gpg --full-generate-key                 # RSA 4096 or ed25519
pass init <your-gpg-key-id>

# store a secret
pass insert volley/anthropic-api-key

# export for a single shell session
export ANTHROPIC_API_KEY="$(pass show volley/anthropic-api-key)"
```

### Option B: `1password-cli` (`op`)

`op` pulls from the 1Password vault using biometric or account unlock. Works well when the same vault is shared across desktop, mobile, and browser.

```sh
# one-time setup
sudo pacman -S 1password-cli            # or: brew install 1password-cli
op signin

# store: add the item via the 1Password app, then reference it by path
export ANTHROPIC_API_KEY="$(op read op://Private/Anthropic/api-key)"
```

Either way, the pattern is the same: the plaintext key never lands in a shell rc file or a config JSON. It lives in the manager, gets read into a variable per-session, and evaporates when the shell exits.

## Wiring the manager into Claude Code

Claude reads MCP env blocks from `~/.claude/settings.json`. Instead of pasting the key value there, keep the value in the manager and launch Claude from a shell that exports the env var first:

```sh
# ~/.zshrc or a dedicated dev-env script, not checked in
export ANTHROPIC_API_KEY="$(pass show volley/anthropic-api-key)"
export LINEAR_API_KEY="$(pass show volley/linear-api-key)"
```

Then the `settings.json` entry becomes a passthrough rather than a secret store:

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "${ANTHROPIC_API_KEY}",
    "LINEAR_API_KEY": "${LINEAR_API_KEY}"
  }
}
```

That file can still be `chmod 600` as defence in depth, but it no longer holds the secret.

## What not to do

- Do not commit any of these keys to the repo, ever. Repo hygiene is covered by `gitleaks` in CI; local discipline has to match.
- Do not paste secrets into shell history. Use the manager's read command or a here-doc.
- Do not share the home directory (`scp -r ~`, cloud sync of `$HOME`, screenshots of terminal) without auditing which files hold secrets first.
- Do not leave a previously-leaked key rotating on a timer. Revoke at the provider, then reissue through the manager.

## Rotation

When a secret has been in a world-readable file at any point, treat it as compromised:

1. Revoke at the provider (Linear, Anthropic, itch.io, GitHub).
2. Issue a new key.
3. Store the new key in `pass` or `op`.
4. Re-export in the shell and restart Claude Code or any long-lived process that cached the old value.

Rotation is cheap. Guessing whether a key leaked is not.
