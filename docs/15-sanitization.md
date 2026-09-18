# 15 — Sanitization

> Publishing a home network's real configuration is its own security incident.
> Everything in `configs/` and `evidence/` passes through this before it's committed.

## Substitution table

| Replace | With | Why |
|---|---|---|
| Real public IP | `<PUBLIC_IP>` | Directly targetable |
| ISP gateway address | `<ISP_GW>` | Narrows your ISP and region |
| Any password, secret, hash, key | `<REDACTED>` | Including type 7 and type 5 hashes |
| ASA `enable password ... encrypted` | `<REDACTED>` | The hash in a `show run` is crackable |
| Device serial numbers | `<SERIAL>` | Ties hardware to a purchase record |
| Xbox gamertags / XUIDs | `<PLAYER>` | Identifies you and your friends |
| Usernames | `<ADMIN_USER>` | Halves a credential-stuffing attempt |
| Domains you own | `<DOMAIN>` | Links the lab to you |

**Keep RFC1918 addresses as they are.** 192.168.x.x and 10.x.x.x aren't routable from the
internet, and redacting them makes the documentation unreadable for no security gain. Saying so
explicitly shows you understand the difference between secrecy and security.

## Specific to this build

Two things appear in real console output from this project and must be scrubbed:

- **The ASA serial number** (`FCH...`) is printed at the top of `show run`. Redact it.
- **The cellular source address** from the external test (`172.56.x.x`) is a carrier NAT address,
  not personally identifying — it is safe to keep, and it is useful evidence that the test came
  from outside the network. Keep it, and say why in the evidence caption.

## Pre-commit checklist

- [ ] No public IPs in configs, docs, or diagrams
- [ ] No password hashes — including `enable secret`, `enable password ... encrypted`, type 7 line passwords, SSH keys
- [ ] Device serial numbers removed from `show run` and `show version` captures
- [ ] Gamertags and XUIDs removed from server log screenshots
- [ ] Screenshots cropped; no unrelated windows, tabs, or hostnames visible
- [ ] `git log -p` reviewed — a secret removed in a later commit is still in the history
- [ ] `.gitignore` covers world data, logs, keys, and `.env` files

## If something leaks anyway

Rotate the credential first — removing the file in a new commit does not remove it from the
repository, and anyone who cloned it already has it. Then rewrite history with
`git filter-repo` (or BFG Repo-Cleaner) and force-push. Assume anything pushed to a public repo
was scraped within minutes.
