# Handling API keys while working on Volley!

If your setup for working on Volley! includes personal API keys on your dev machine, this doc collects some hygiene habits that keep them out of world-readable files and out of the repo. It is aimed at open-source contributors, so the advice is optional where it needs to be: a contributor touching only Godot scenes can skip most of it, and a contributor wiring up third-party tooling can cherry-pick the parts that match their setup.

The rule in one line: a secret belongs in a manager that prompts for unlock, not in a file that any process running as your user can read.

## What a "secret" might look like

Concretely, the sort of credential that benefits from this treatment is any long-lived token that calls a third-party service on your behalf. Examples a contributor might have lying around (none of these are required to work on Volley!):

- API keys for any AI or LLM provider you use while coding.
- API keys for project-management services (for example: Linear, Jira, GitHub tokens used outside `gh auth`).
- Publishing or deployment tokens (for example: `butler` for itch.io, registry credentials).
- MCP server credentials, if you run an editor or agent that speaks MCP.

Tokens that already live inside a managed store, like `gh auth` or `op signin`, are already covered. This doc is about the ones that tend to drift into plaintext config files instead.

## Baseline: tighten file modes on anything that holds a key

The one habit worth picking up regardless of toolchain is making sure home-directory files that hold credentials are not world-readable. Many tools ship config files at mode `644` and then invite you to paste a key into them.

```sh
# for any file in your home directory that holds a plaintext credential
chmod 600 <path>
```

A sweep that surfaces candidates:

```sh
# audit world-readable files under ~/.config and in the top of $HOME
find ~/.config -type f -perm /044 -print
find ~ -maxdepth 2 -type f -name '.*' -perm /044 -print
```

Common suspects: `~/.netrc`, `~/.pypirc`, `~/.npmrc`, `~/.config/gh/hosts.yml`, per-tool `*.yml`, `*.toml`, `*.env`, and any editor or agent settings that accept an `env` block.

If a file needs to stay world-readable (a checked-in sample config, a public key), it should not contain a secret in the first place. Move the secret out, then relax the mode.

## Migration path: move secrets into a manager

Two general-purpose options. Either is fine; pick the one that fits your workflow.

### Option A: `pass` (gpg-backed, filesystem store)

`pass` encrypts each secret as a `.gpg` file under `~/.password-store/`. Unlock with the gpg agent, read with a single command.

```sh
# one-time setup
sudo pacman -S pass                     # or: brew install pass
gpg --full-generate-key                 # RSA 4096 or ed25519
pass init <your-gpg-key-id>

# store a secret
pass insert example/some-api-key

# export for a single shell session
export SOME_API_KEY="$(pass show example/some-api-key)"
```

### Option B: `1password-cli` (`op`)

`op` pulls from the 1Password vault using biometric or account unlock. Works well when the same vault is shared across desktop, mobile, and browser.

```sh
# one-time setup
sudo pacman -S 1password-cli            # or: brew install 1password-cli
op signin

# store: add the item via the 1Password app, then reference it by path
export SOME_API_KEY="$(op read op://Private/Example/api-key)"
```

Either way, the pattern is the same: the plaintext key never lands in a shell rc file or a config JSON. It lives in the manager, gets read into a variable per-session, and evaporates when the shell exits.

## An on-demand shell session for dev work

Rather than exporting every key in `~/.zshrc` or `~/.bashrc` (which fires an unlock prompt on every new shell), keep an opt-in script that you `source` when you start a session that actually needs the keys.

```sh
# ~/bin/dev-env (or anywhere on PATH), not checked in
export SOME_API_KEY="$(pass show example/some-api-key)"
export OTHER_API_KEY="$(pass show example/other-api-key)"
```

Then:

```sh
source ~/bin/dev-env   # one GPG prompt, once, when you actually want the keys
# ...launch your editor or tool here
```

One unlock per work session, zero keys in rc files.

## Repo and history hygiene

- Do not commit keys to the repo. `gitleaks` runs in CI; local habits should match.
- Do not paste secrets into shell history. Use the manager's read command, or a here-doc.
- Do not share the home directory (`scp -r ~`, cloud sync of `$HOME`, terminal screenshots) without auditing which files hold secrets first.
- If a key has ever sat in a world-readable file, treat it as compromised: revoke at the provider, issue a new one, store it in the manager, re-export in the shell, and restart any long-lived process that cached the old value.

## Appendix: if you use Claude Code

Skip this section if you do not use Claude Code; the rest of the doc stands on its own.

Claude Code reads MCP environment variables from `~/.claude/settings.json`. That file ships at mode `644`, and MCP `env` blocks are a natural place for keys to accumulate, so it is worth both tightening the mode and keeping the key values out of the file.

```sh
chmod 600 ~/.claude/settings.json
chmod 600 ~/.claude/settings.local.json  # if present
```

With the `dev-env` pattern above in place, the settings file becomes a passthrough rather than a secret store:

```json
{
  "env": {
    "SOME_API_KEY": "${SOME_API_KEY}",
    "OTHER_API_KEY": "${OTHER_API_KEY}"
  }
}
```

Launch Claude from a shell that has `source`d `dev-env`, and the values resolve from the environment. The settings file can still be `chmod 600` as defence in depth, but it no longer holds the secret.
