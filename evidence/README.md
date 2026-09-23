# Evidence

Proof for every claim in [`../docs/13-validation-tests.md`](../docs/13-validation-tests.md).

## Captured

| File | Test | Shows |
|---|---|---|
| `bedrock-player-connected.png` | T-01 | Server log: player connected, spawned, disconnected — external client over cellular |
| `config-register.png` | T-02 | `Configuration register is 0x2102` on the 1921 after reload |
| `asa-config-persisted.png` | T-02 | ASA `show run` intact after `reload` |
| `inside-egress.png` | T-03 | Client on the 2960X reaching 8.8.8.8 through the ASA and 1921 |
| `dmz-egress.png` | T-04 | DMZ host reaching 8.8.8.8 after reboot |
| `udp-listener-external.png` | T-05 | Raw UDP packet received from 172.56.161.184 — external cellular source |
| `nat-translation-table.png` | T-06 | 1921 static translation `192.168.1.147:19132 → 192.168.20.10:19132` |
| `route-to-dmz.png` | T-06 | `show ip route 192.168.20.0` → static via 192.168.100.2 |

## Still needed

| File | Test | How to capture |
|---|---|---|
| `acl-hit-counters.png` | T-09 | `show access-list OUTSIDE-IN` — **after** live sessions. Line 1 counter must be non-zero |
| `asa-live-conn.png` | T-09 | `show conn address 192.168.20.10` while a player is connected |
| `dmz-to-inside-denied.png` | T-07 | Attempt to reach 192.168.10.x from the DMZ host, then `show access-list DMZ-IN` — line 1 must increment |
| `asa-deny-log.png` | T-10 | `show logging \| include deny` after triggering T-07 |
| `switch-vlan-status.png` | T-11 | `show vlan brief` and `show interfaces status` on the 2960X |
| `external-port-scan.png` | T-08 | `nmap` against the public IP from outside the network |
| `rack-photo.jpg` | — | Physical shot of the 1921 → ASA → 2960X chain |

## Naming

Prefix with the test ID where one applies, so the validation table links straight to the proof:
`T-07-dmz-to-inside-denied.png`, `T-09-acl-hit-counters.png`.

## Before committing

- [ ] Real public IP redacted from every screenshot and capture
- [ ] **ASA serial number** redacted — it appears at the top of `show run`
- [ ] **Gamertags and XUIDs** redacted from server log screenshots
- [ ] Cropped — no unrelated windows, browser tabs, or desktop visible
- [ ] Prefer `.txt` command output over screenshots where possible: searchable, diffable, smaller

The cellular source address (172.56.x.x) is a carrier NAT address, not personally identifying.

See [`../docs/15-sanitization.md`](../docs/15-sanitization.md).
