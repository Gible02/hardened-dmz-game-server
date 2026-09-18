# 13 — Validation Tests

> Every security claim in the README needs a test here that proves it, with evidence in `evidence/`.
> An untested control is an assumption.

## Test matrix

| ID | Claim tested | Method | Expected | Actual | Evidence | Date |
|---|---|---|---|---|---|---|
| T-01 | Service reachable from the internet | Bedrock client on cellular → `<PUBLIC_IP>:19132` | Connects and spawns | **PASS** — connect, spawn, disconnect all logged | `bedrock-player-connected.png` | 2026-09-14 |
| T-02 | Config survives reload | `reload` both devices, re-read config | Config intact, register 0x2102 | **PASS** | `config-register.png` | 2026-09-14 |
| T-03 | Inside zone reaches the internet | DHCP client on 2960X → ping 8.8.8.8 | Lease obtained, ping succeeds | **PASS** | `inside-egress.png` | 2026-09-14 |
| T-04 | DMZ zone reaches the internet | From 192.168.20.10 → ping 8.8.8.8, DNS | Succeeds | **PASS** | `dmz-egress.png` | 2026-09-14 |
| T-05 | External UDP reaches the DMZ host | Raw UDP listener on 19132, send from cellular | Packet received from external source | **PASS** — received from 172.56.161.184 | `udp-listener-external.png` | 2026-09-14 |
| T-06 | Inbound NAT and route correct | `show ip nat translations`, `show ip route 192.168.20.0` | Static entry + route present | **PASS** | `nat-translation-table.png` | 2026-09-14 |
| T-07 | DMZ cannot reach the trusted LAN | From 192.168.20.10: ping/scan 192.168.10.0/24 | Denied, `DMZ-IN` line 1 increments | *Not yet run* | `dmz-to-inside-denied.png` | — |
| T-08 | Only UDP 19132 exposed | `nmap -sU`/`-sT` against `<PUBLIC_IP>` from outside | 19132 only | *Not yet run* | — | — |
| T-09 | ACLs matching real traffic | `show access-list OUTSIDE-IN` after live sessions | Line 1 counter non-zero | *Capture pending* | `acl-hit-counters.png` | — |
| T-10 | Denied flows are logged | Trigger T-07, read ASA log | Deny entries with src/dst | *Not yet run* | — | — |
| T-11 | Switch hardening applied | `show vlan brief`, `show interfaces status` | Unused ports shut in VLAN 999 | *Not yet run* | — | — |
| T-12 | Egress default-deny holds | From 192.168.20.10 reach an arbitrary host/port | Blocked, `DMZ-IN` line 8 increments | *Staged — see doc 16* | — | — |
| T-14 | Auth survives egress filtering | Player disconnect/reconnect after applying doc 16 | `online-mode` auth succeeds | *Staged* | — | — |
| T-15 | Infrastructure unreachable from DMZ | From 192.168.20.10: reach 192.168.1.1, 192.168.100.1 | Denied, lines 2-3 increment | *Staged* | — | — |
| T-13 | Backup restores to a working world | Restore to a scratch host and boot | Loads, loss within RPO | *Control not built* | — | — |

## Commands used

```
# T-02 — config persistence
show version | include register            # 1921  → Configuration register is 0x2102
show run                                   # ASA   → full config intact after reload

# T-06 — translation and route
show ip nat translations                   # 1921
show ip route 192.168.20.0                 # 1921
show run | section ip nat                  # 1921

# T-05 — external UDP reachability, independent of the game
# on the DMZ host:
$udp = New-Object System.Net.Sockets.UdpClient(19132)
$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
$bytes = $udp.Receive([ref]$endpoint)
Write-Host "Received from $($endpoint.Address):$($endpoint.Port)"
[System.Text.Encoding]::UTF8.GetString($bytes)

# T-07 — containment (run these next)
# from the DMZ host:
ping 192.168.10.1
Test-NetConnection 192.168.10.1 -Port 445
# then on the ASA:
show access-list DMZ-IN                    # line 1 counter must increment
show logging | include deny

# T-09 — ACL hit counters after live traffic
show access-list OUTSIDE-IN
show conn address 192.168.20.10            # run while a player is connected
```

## Note on T-09

ACL counters were read earlier in the build while the inbound path was still broken and
correctly showed `hitcnt=0` — that zero was the diagnostic clue that led to the NAT and routing
fixes. They have not been re-read since traffic started flowing. A non-zero counter on
`OUTSIDE-IN` line 1 is the single clearest proof in this repo that the rule is doing work.

## Known gaps

| Gap | Why not covered | Planned? |
|---|---|---|
| No IDS/IPS | Out of scope for v1; ASA 5515-X FirePOWER module not licensed | Future |
| No centralized logging | Logs are local to each device | Future — syslog to an inside collector |
| Egress filtering staged but not applied | See R-05, R-11 | Runbook ready: [`16-egress-filtering.md`](16-egress-filtering.md) |
