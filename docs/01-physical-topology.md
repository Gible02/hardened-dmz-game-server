# 01 — Physical Topology

![Physical topology](../diagrams/physical-topology.png)

## Cable trace

| From | Port | To | Port | Purpose |
|---|---|---|---|---|
| Optimum ONT (Altice GR140IG) | LAN | Cisco 1921 | Gi0/0 | Internet handoff |
| Cisco 1921 | Gi0/1 | ASA 5515-X | Gi0/3 | Transit link, 192.168.100.0/30 |
| ASA 5515-X | Gi0/0 | Catalyst 2960X | `<PORT>` | Inside / trusted |
| ASA 5515-X | Gi0/2 | Game server host | onboard NIC | DMZ — direct, no switch in path |

## Why three-legged

The DMZ host sits on its own physical firewall interface rather than a switch VLAN, so DMZ and
trusted traffic are separated before any filtering decision is made. The cost is a consumed
firewall port and no ability to scale past a few DMZ hosts. The benefit is that a switch
misconfiguration — a mistyped VLAN, a trunk left negotiating — cannot merge the zones.

## Hardware notes

| Device | Model | Notes |
|---|---|---|
| Router | Cisco 1921 ISR | IOS 15.4(3)M3, C1900-UNIVERSALK9-M. End-of-support — see R-01. Config register 0x2102, verified persistent |
| Firewall | Cisco ASA 5515-X | ASA 9.3(3), 8192 MB RAM, serial FCH200571EJ. **Gi0/1 is physically faulty on this unit.** No expansion module — only Gi0/0–Gi0/5 exist |
| Switch | Catalyst WS-C2960X-48LPS-L | Cabled and passing traffic; hardening config not yet confirmed applied |
| Server | Intel i3-13100F / 16 GB RAM / 1 TB HDD | Windows 11 |

Both hardware surprises are written up in [`14-troubleshooting-log.md`](14-troubleshooting-log.md).
