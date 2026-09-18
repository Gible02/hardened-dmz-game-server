# Changelog

## 2026-09-15 — Egress filtering designed (C-03)

### Added
- `docs/16-egress-filtering.md` — staged four-phase runbook closing C-03, with discovery,
  staging, enforcement, host-layer scoping, validation, and rollback.
- **R-11** to the risk register: the DMZ host can currently reach the ISP gateway, the 1921, and
  the ASA's own outside interface. `deny ip object DMZ-NET object INSIDE-NET` covers the trusted
  LAN only; infrastructure addresses sit outside that object. Found while writing the egress ACL.
- `configs/windows-firewall.ps1` outbound rules scoped to `bedrock_server.exe` — process-level
  identity the ASA cannot see.
- T-14 and T-15 to the validation matrix.

### Changed
- `DMZ-IN` rewritten in `configs/asa-5515x.sanitized.txt`: two infrastructure denies, four named
  egress permits (DNS, NTP, HTTPS, QUIC), explicit logged deny. Deny-before-permit ordering.
- C-03 status: "Not implemented" → "Designed, staged rollout ready".
- R-05 residual risk stated explicitly rather than implying full coverage: HTTPS-based C2 and DNS
  tunnelling remain possible. Strict destination allowlisting and ASA FQDN objects were both
  evaluated and rejected, with reasons recorded.

## 2026-09-14 — Build validated end to end

**Core architecture proven.** An external Minecraft Bedrock client on a cellular connection
connected, authenticated, and spawned through the full chain: Optimum gateway → Cisco 1921 →
ASA 5515-X → DMZ host.

### Fixed
- **Config register** on the 1921 was `0x2142`, discarding configuration on every reload.
  Corrected to `0x2102` and verified by reload.
- **Inbound static NAT** was absent entirely, then initially targeted the ASA's outside
  interface (`192.168.100.2`) instead of the real host. Retargeted to `192.168.20.10` — the ASA
  performs no NAT, so the destination must be the end host.
- **Missing static route** on the 1921 for `192.168.20.0/24`. Added via `192.168.100.2`.
- **Missing Visual C++ Redistributable** on the server host, causing `bedrock_server.exe` to
  exit silently with `0xC0000135`.
- **Server installed inside OneDrive.** Moved to `C:\McServer\` to avoid sync-related world
  corruption.

### Changed
- **Server platform: Ubuntu + Docker Compose → Windows 11 + native Bedrock `.exe`.** No Linux
  boot option available on the host. Consequences: `nftables.conf` and `docker-compose.yml`
  removed from `configs/`; container isolation and nftables egress control no longer apply.
- Control numbering revised; the controls table now carries an explicit status column rather
  than implying everything listed is implemented.

### Added
- `docs/14-troubleshooting-log.md` expanded to nine documented failures with diagnosis paths.
- `configs/server.properties` and `configs/windows-firewall.ps1`.
- `scripts/pull-backup.ps1` and `validate-egress.ps1` — PowerShell replacements for the
  shell versions.
- Explicit gap notes for C-03 (default-deny egress) and R-05, which the platform change left
  unimplemented.

### Known gaps carried forward
- C-03 default-deny egress — not implemented. Highest-value remaining work.
- C-02 containment rule — configured but untested (T-07).
- C-07 switch hardening — not confirmed applied.
- C-11 pull-based backups, C-12 config drift detection — designed, not built.
