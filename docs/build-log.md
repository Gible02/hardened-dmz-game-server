# Build Log

Nine phases, preflight through validation. The dead ends stay in — they're the raw material for
[`14-troubleshooting-log.md`](14-troubleshooting-log.md).

## Phase 1 — Preflight
- [x] Hardware inventory: 1921, ASA 5515-X, 2960X, i3-13100F host
- [x] Console access established over serial
- [x] Firmware versions recorded — IOS 15.4(3)M3, ASA 9.3(3)
- [x] ASA module inventory: no expansion module, Gi0/0–Gi0/5 only

## Phase 2 — Physical build and cable trace
- [x] Cables traced against the topology diagram
- [x] **Found:** ISP feed patched directly into the 2960X, bypassing router and firewall
- [x] **Found:** ASA Gi0/1 physically faulty; outside relocated to Gi0/3
- [x] Final mapping confirmed: ASA Gi0/0 inside, Gi0/2 dmz, Gi0/3 outside

## Phase 3 — ISP verification
- [x] CGNAT check via traceroute — public Optimum address at hop 2, no CGNAT
- [x] Static port forward UDP 19132 configured by ISP support
- [x] 1921 WAN set static (192.168.1.147) — no DHCP reservation on residential plan

## Phase 4 — Edge router (1921)
- [x] Interfaces and addressing
- [x] **Found:** config register 0x2142 discarding config on reload — corrected to 0x2102
- [x] **Found:** `ip nat outside` and the PAT overload statement both missing — added
- [x] **Found:** no inbound static NAT — added, initially with the wrong target
- [x] **Found:** no route to 192.168.20.0/24 — added
- [x] Persistence verified by reload

## Phase 5 — Firewall (ASA 5515-X)
- [x] **Found:** residual WireGuard-style ACL on "factory default" hardware — `write erase` + reload
- [x] Three interfaces configured with security levels
- [x] Objects: MC-SERVER, DMZ-NET, INSIDE-NET
- [x] `OUTSIDE-IN` and `DMZ-IN` ACLs written and applied
- [x] DHCP enabled on inside
- [x] Config persistence verified by reload

## Phase 6 — Switch (2960X) and VLANs
- [x] Physically connected to ASA Gi0/0
- [x] Trusted-side client confirmed reaching the internet
- [ ] VLAN configuration applied and verified
- [ ] L2 hardening applied and verified

## Phase 7 — Host build and hardening
- [x] Windows 11 host at 192.168.20.10
- [x] **Decision:** native Bedrock `.exe` over Docker — no Linux boot option available
- [x] **Found:** silent exit `0xC0000135` — missing Visual C++ Redistributable, installed
- [x] **Found:** install path inside OneDrive — moved to `C:\McServer\`
- [x] Windows Firewall inbound rule for UDP 19132
- [x] `online-mode=true`, `allow-list=true`, allowlist populated
- [ ] Default-deny egress
- [ ] Least-privilege service account / run as service

## Phase 8 — Backup and recovery
- [ ] Pull-based backup script
- [ ] ASA inside→dmz rule for the backup host
- [ ] One real restore test

## Phase 9 — Validation
- [x] T-01 external game connection from cellular — connect, spawn, disconnect logged
- [x] T-02 config persistence across reload
- [x] T-03 inside zone to internet
- [x] T-04 DMZ zone to internet
- [x] T-05 raw external UDP reaching the DMZ host
- [x] T-06 NAT translation and route present
- [ ] T-07 DMZ→inside containment
- [ ] T-08 external port scan
- [ ] T-09 ACL hit counters after live traffic
- [ ] T-11 switch hardening verification
