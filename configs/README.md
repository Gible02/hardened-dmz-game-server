# Configs

Sanitized configurations for every device and host. **Read
[`../docs/15-sanitization.md`](../docs/15-sanitization.md) before committing anything here.**

| File | Device | Build doc | State |
|---|---|---|---|
| `cisco-1921.sanitized.txt` | Cisco 1921 ISR | [`04-router-1921.md`](../docs/04-router-1921.md) | **deployed, verified** |
| `asa-5515x.sanitized.txt` | Cisco ASA 5515-X | [`05-asa-5515x.md`](../docs/05-asa-5515x.md) | **deployed, verified** |
| `catalyst-2960x.sanitized.txt` | Catalyst 2960X | [`06-switch-2960x.md`](../docs/06-switch-2960x.md) | draft — not confirmed applied |
| `server.properties` | Bedrock Dedicated Server | [`07-host-hardening.md`](../docs/07-host-hardening.md) | **deployed, verified** |
| `windows-firewall.ps1` | Windows 11 host firewall | [`07-host-hardening.md`](../docs/07-host-hardening.md) | inbound deployed; egress section not built |

Every address here must match [`../docs/03-addressing-and-vlans.md`](../docs/03-addressing-and-vlans.md).
The reasoning behind each config lives in its build doc, not in comments here.

**Removed from the original scaffold:** `nftables.conf` and `docker-compose.yml`. The host runs
Windows 11 with the native Bedrock server, so neither applies. The controls they carried are
tracked as open items in the README rather than as configs for a platform that isn't in use.
