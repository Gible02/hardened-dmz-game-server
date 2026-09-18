# 09 — Hardening Baseline

> Control → implementation → verification command → status.
> Nothing is marked ☑ until the verify command has actually been run against the live device.

## Cisco 1921

| # | Control | Implementation | Verify with | Status |
|---|---|---|---|---|
| 1 | Config register correct | `config-register 0x2102` | `show version \| include register` | ☑ verified |
| 2 | NAT outbound (PAT) | `ip nat inside source list NAT-SOURCES interface Gi0/0 overload` | `show ip nat translations` | ☑ verified |
| 3 | NAT inbound, single port | `ip nat inside source static udp 192.168.20.10 19132 interface Gi0/0 19132` | `show run \| section ip nat` | ☑ verified |
| 4 | Route to DMZ | `ip route 192.168.20.0 255.255.255.0 192.168.100.2` | `show ip route 192.168.20.0` | ☑ verified |
| 5 | Unused services disabled | `no ip http server`, `no ip http secure-server` | `show run \| include http` | ☐ |
| 6 | Edge ACL applied inbound | `<ACL NAME>` | `show access-lists` | ☐ |
| 7 | SSH only, telnet disabled | `transport input ssh` | `show run \| section line vty` | ☐ |
| 8 | Enable secret set | `enable secret <REDACTED>` | `show run \| include enable` | ☐ |
| 9 | Logging enabled | `logging buffered` | `show logging` | ☐ |

## ASA 5515-X

| # | Control | Implementation | Verify with | Status |
|---|---|---|---|---|
| 1 | Security levels per zone | inside 100 / dmz 50 / outside 0 | `show nameif` | ☑ verified |
| 2 | Single exposed service | `OUTSIDE-IN` line 1 | `show access-list OUTSIDE-IN` | ☑ verified |
| 3 | Explicit deny + log on outside | `OUTSIDE-IN` line 5 | `show access-list OUTSIDE-IN` | ☑ verified |
| 4 | DMZ → inside deny + log | `DMZ-IN` line 1 | `show access-list DMZ-IN` | ☑ config present, ☐ **untested** |
| 5 | ACLs applied to interfaces | `access-group ... in interface ...` | `show run access-group` | ☑ verified |
| 6 | Config persists across reload | `write mem` | `show run` after `reload` | ☑ verified |
| 7 | DHCP scoped to inside only | `dhcpd enable inside` | `show run \| include dhcpd` | ☑ verified |
| 8 | Default-deny egress from DMZ | `DMZ-IN` lines 2-8 — see doc 16 | `show access-list DMZ-IN` | ☐ **staged, not applied** |
| 9 | Threat detection | `threat-detection basic-threat` | `show threat-detection statistics` | ☐ |
| 10 | Logging to buffer or host | `logging enable`, `logging buffered` | `show logging` | ☐ |
| 11 | Mgmt restricted by source | `ssh <MGMT_SUBNET> <MASK> inside` | `show run ssh` | ☐ |

## Catalyst 2960X

| # | Control | Implementation | Verify with | Status |
|---|---|---|---|---|
| 1 | Uplink to ASA inside | `<UPLINK_PORT>` | `show interfaces status` | ☑ passing traffic |
| 2 | Unused ports → VLAN 999, shut | `switchport access vlan 999` + `shutdown` | `show interfaces status` | ☐ |
| 3 | DTP disabled on access ports | `switchport nonegotiate` | `show interfaces trunk` | ☐ |
| 4 | BPDU guard | `spanning-tree bpduguard enable` | `show spanning-tree summary` | ☐ |
| 5 | Port security | `switchport port-security` | `show port-security` | ☐ |
| 6 | Native VLAN not 1 | `switchport trunk native vlan <NOT_1>` | `show interfaces trunk` | ☐ |
| 7 | Management VLAN separated | VLAN 99 | `show vlan brief` | ☐ |

## Server host — Windows 11

| # | Control | Implementation | Verify with | Status |
|---|---|---|---|---|
| 1 | Host firewall enabled, single exception | `New-NetFirewallRule ... UDP 19132 Inbound Allow` | `Get-NetFirewallRule -DisplayName "Minecraft Bedrock"` | ☑ verified |
| 2 | Server data off cloud sync | Moved to `C:\McServer\` | Path check | ☑ verified |
| 3 | Outbound scoped to `bedrock_server.exe` | `windows-firewall.ps1` — see doc 16 phase 4 | `Get-NetFirewallRule -Direction Outbound` | ☐ **staged, not applied** |
| 4 | Least-privilege service account | not built — runs interactively | `whoami` in the server session | ☐ |
| 5 | Runs as a service, auto-start | not built | `Get-Service` | ☐ |
| 6 | OS patching current | `<FILL>` | `Get-HotFix \| Sort-Object InstalledOn` | ☐ |

## Application — Bedrock Dedicated Server

| # | Control | Implementation | Verify with | Status |
|---|---|---|---|---|
| 1 | Xbox Live auth enforced | `online-mode=true` | `server.properties` | ☑ verified |
| 2 | Allowlist enforced | `allow-list=true` + populated `allowlist.json` | Console: `allowlist list` | ☑ verified |
| 3 | Cheats disabled | `allow-cheats=false` | `server.properties` | ☑ verified |
| 4 | Player cap set | `max-players=5` | `server.properties` | ☑ verified |
| 5 | LAN discovery disabled | `enable-lan-visibility=false` | `server.properties` | ☐ |
| 6 | Operator privileges minimized | `permissions.json` reviewed | `permissions.json` | ☐ |
