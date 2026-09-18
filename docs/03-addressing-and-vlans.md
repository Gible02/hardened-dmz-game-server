# 03 — Addressing and VLANs

> **Single source of truth.** Every config in `configs/` and every diagram in `diagrams/`
> must agree with this page. If they disagree, this page is right and the other one is a bug.

## IP addressing

| Device | Interface | Zone | IP / Mask | Gateway | Notes |
|---|---|---|---|---|---|
| Optimum ONT | LAN | — | `<GATEWAY_IP>` | — | Static forward UDP 19132 → 192.168.1.147 |
| Cisco 1921 | Gi0/0 | outside | 192.168.1.147 | `<ISP_GW>` | Static — no DHCP reservation on residential plan. `ip nat outside` |
| Cisco 1921 | Gi0/1 | transit | 192.168.100.1/30 | — | `ip nat inside` |
| ASA 5515-X | Gi0/3 | outside | 192.168.100.2/30 | 192.168.100.1 | Moved from Gi0/1 (faulty port) |
| ASA 5515-X | Gi0/0 | inside | 192.168.10.1/24 | — | To 2960X. Serves DHCP |
| ASA 5515-X | Gi0/2 | dmz | `<DMZ_IF_IP>`/24 | — | Direct to game server host. **Read back and fill** |
| Game server | onboard NIC | dmz | 192.168.20.10/24 | `<DMZ_IF_IP>` | Static |
| `<BACKUP_HOST>` | — | inside | `<IP>` | 192.168.10.1 | Not yet built — see C-11 |
| `<MGMT_HOST>` | — | inside | `<IP>` | 192.168.10.1 | Console / SSH origin |

## Subnets

| Subnet | Purpose | Usable range | DHCP? |
|---|---|---|---|
| 192.168.100.0/30 | 1921 ↔ ASA transit | .1 – .2 | No |
| 192.168.20.0/24 | DMZ | .10 in use | No — static only |
| 192.168.10.0/24 | Trusted LAN | .100 – .200 | Yes — ASA `dhcpd`, inside interface |

## ASA network objects

| Object | Type | Value | Used by |
|---|---|---|---|
| `MC-SERVER` | host | 192.168.20.10 | `OUTSIDE-IN` line 1 |
| `DMZ-NET` | subnet | 192.168.20.0/24 | `DMZ-IN` lines 1 and 2 |
| `INSIDE-NET` | subnet | 192.168.10.0/24 | `DMZ-IN` line 1 |

## VLANs — Catalyst 2960X

> Not yet confirmed applied on the live switch. Verify with `show vlan brief` and
> `show interfaces status` before marking C-07 complete.

| VLAN | Name | Purpose | Ports | Gateway |
|---|---|---|---|---|
| 10 | TRUSTED | Trusted LAN | `<FILL>` | 192.168.10.1 (ASA inside) |
| 99 | MGMT | Management | `<FILL>` | `<FILL>` |
| 999 | BLACKHOLE | Unused ports, shut down | all unassigned | none |

VLAN 20 existed in the original VLAN-based DMZ design and was removed when the DMZ became a
physical ASA interface. The gap in numbering is deliberate, not an omission.

## Ports and services

| Service | Protocol / Port | Source | Destination | Exposed externally? |
|---|---|---|---|---|
| Minecraft Bedrock | UDP 19132 | Internet | 192.168.20.10 | **Yes — the only one** |
| Bedrock IPv6 listener | UDP 19133 | — | 192.168.20.10 | No — not forwarded |
| ICMP echo-reply / unreachable / time-exceeded | ICMP | Internet | any | Yes — path MTU and traceroute only |
| Backup pull | `<PROTO/PORT>` | `<BACKUP_HOST>` | 192.168.20.10 | No — not yet built |
