# 06 — Catalyst WS-C2960X-48LPS-L (Access Switch)

Config: [`../configs/catalyst-2960x.sanitized.txt`](../configs/catalyst-2960x.sanitized.txt)
Status: **cabled and passing traffic. hardening config NOT confirmed applied**

## Role

Trusted-side layer 2. Carries the inside VLANs and uplinks to the ASA's inside interface —
**not** to the router. That retargeting was part of the move to a three-legged design.

## What is verified

A client on this switch pulls a DHCP lease from the ASA and reaches the internet through the
ASA and the 1921's PAT. The physical path and the inside zone both work.

## What is not verified

Everything in the hardening table below. The switch is functioning but its security
configuration has not been read back from the live device. **Do not mark C-07 complete until
`show vlan brief` and `show interfaces status` confirm it.**

## L2 hardening

| Control | Implementation | Why | Status |
|---|---|---|---|
| Unused ports → VLAN 999, shut | `switchport access vlan 999` + `shutdown` | An open patch port is an unauthenticated network drop | `<☐>` |
| DTP disabled | `switchport nonegotiate` | Prevents VLAN hopping via trunk negotiation | `<☐>` |
| BPDU guard on access ports | `spanning-tree bpduguard enable` | Stops a rogue switch influencing spanning tree | `<☐>` |
| Port security | `<FILL>` | Limits MAC addresses per port | `<☐>` |
| Native VLAN ≠ VLAN 1 | `switchport trunk native vlan <NOT_1>` | Mitigates double-tagging | `<☐>` |
| Management on VLAN 99 | `interface Vlan99` | Separates management plane from user traffic | `<☐>` |

## Design change to explain

The original design had a VLAN-based DMZ (VLAN 20) with the switch trunking to the router.
When the DMZ moved to a dedicated ASA interface, VLAN 20 was dropped and the uplink was
retargeted to the ASA's inside port. The better design: the DMZ is now separated from the
trusted LAN by a physical interface boundary and a stateful firewall, rather than by a VLAN
tag that a switch misconfiguration could erase.

## Verification

```
show vlan brief
show interfaces status
show interfaces trunk
show port-security
show spanning-tree summary
```
