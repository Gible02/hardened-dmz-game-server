# 07 — Server Host Hardening

Configs: [`../configs/server.properties`](../configs/server.properties) · [`../configs/windows-firewall.ps1`](../configs/windows-firewall.ps1)
Status: **partially implemented** — inbound controls done, egress filtering outstanding

## Host details

| Item | Value |
|---|---|
| Hardware | Intel i3-13100F / 16 GB RAM / 1 TB HDD |
| OS | Windows 11 |
| Zone | dmz — ASA Gi0/2 |
| IP | 192.168.20.10 (static) |
| Server software | Minecraft Bedrock Dedicated Server, native `.exe` |
| Install path | `C:\McServer\` |

## Platform change from the original design

The hardening design assumed Ubuntu Server 24.04 with nftables and a hardened Docker Compose
stack. No Linux boot option was available on this host, so the build moved to the native
Windows Bedrock server.

What was lost, and what replaces it:

| Original control | Status on Windows | Replacement |
|---|---|---|
| nftables default-deny egress | Unavailable | Windows Defender Firewall outbound rules, or an ASA egress ACL. **Not yet built** |
| Container isolation (cap_drop, read-only FS, non-root) | Not applicable — no container | Service account scoping and least-privilege on the install directory. **Not yet built** |
| Pinned image digest | Not applicable | Manual version tracking against the official download |

Recorded here rather than removed, because the delta between the designed and built states is
itself part of the documentation.

## Implemented controls

**Host firewall exception, not disable.** A single inbound rule permits UDP 19132. The common
shortcut — disabling Windows Defender Firewall to "make it work" — would undo the host layer
entirely.

```powershell
New-NetFirewallRule -DisplayName "Minecraft Bedrock" `
  -Direction Inbound -Protocol UDP -LocalPort 19132 -Action Allow
```

**Application-layer authentication.** Reaching the open port is not the same as reaching the
game:

| Setting | Value | Effect |
|---|---|---|
| `online-mode` | `true` | Xbox Live authentication enforced for every connecting client |
| `allow-list` | `true` | Only named gamertags admitted, even after authentication |
| `allow-cheats` | `false` | No command access for connected players |
| `max-players` | 5 | Bounds resource consumption |

**Server data off cloud sync.** The install was initially extracted inside OneDrive. Live world
database writes under an active sync client risk corruption, sync conflicts, and file locks
that crash the server mid-session. Moved to `C:\McServer\`.

## Outstanding

| Control | Why it matters | Status |
|---|---|---|
| Default-deny egress | Kills reverse shells, C2 beaconing, miner callbacks from a compromised host | **Not built** |
| Least-privilege service account | Server currently runs in an interactive admin session | **Not built** |
| Run as a service with auto-start | Currently requires a logged-in console window | **Not built** |
| Automatic update tracking | Bedrock releases are manual downloads with no update channel | **Not built** |

## Verification

```powershell
Get-NetFirewallRule -DisplayName "Minecraft Bedrock" | Format-List
Get-NetFirewallRule -Direction Outbound -Enabled True | Measure-Object
Get-Content C:\McServer\server.properties | Select-String "online-mode|allow-list|allow-cheats"
netstat -an | Select-String "19132"
```
