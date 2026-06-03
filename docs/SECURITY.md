# Security

## Reporting vulnerabilities

Open a private issue or contact the maintainer: [RenatoAntonioCL](https://github.com/RenatoAntonioCL).

## Threat model (summary)

See [ARCHITECTURE.md §8](../ARCHITECTURE.md):

- Path traversal in `blueprint.toml` — relative paths validated.
- Prompt injection — the focal chunk is treated as data, not instructions.
- Ollama on the network — preflight requires `127.0.0.1` (Week 3).

## Secret handling

- **Unique per project.** Each generated project receives its own secrets via
  `openssl rand` (fallback `/dev/urandom`). No fixed values or `changeme`.
- **Never reach git.** The generated `.env` is ignored by default (the `.gitignore`
  that GenPy creates includes `.env`) and has `600` permissions (owner-read only).
- **Templates without real secrets.** The `.env` files versioned in `templates/` contain
  only placeholders (`{{SECRET_HEX_N}}`) or dummy values; no real credentials.
- **GitHub token.** Read silently (`read -rsp`) from `GITHUB_TOKEN` /
  `GH_TOKEN` / `gh`, and sent to the API via stdin (`curl -H @-`), never as an argument,
  so it does not appear in the process list (`ps`).

## Installation and update integrity

- Installation copies from the local repository; no `curl | bash`.
- The updater clones the `main` branch over **HTTPS** (authenticity via GitHub's TLS) and
  **verifies the structural integrity of the clone** (key files present and non-empty)
  **before** replacing the installation: if the clone is incomplete, it aborts without
  destroying the working version. Reports the commit it updates to.
- Future improvement: **GPG signature** verification of tags / pin to a signed release.

## Security blueprints (cyber)

For authorized labs only. Do not deploy on production networks.
