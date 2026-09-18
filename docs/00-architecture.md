# 00 — Architecture

## Design principles

1. Assume breach of the exposed host. Every other decision follows from this.
2. Enforce segmentation in hardware. Host firewalls are a second layer, never the only one.
3. Every permitted flow is explicit, justified, and logged.
4. Prove controls work. An untested control is an assumption.
5. If it isn't documented, it isn't done — including the parts that aren't finished.

## Zone model

| Zone | Interface | Security level | Contains | May initiate to |
|---|---|---|---|---|
| outside | ASA Gi0/3 | 0 | Internet, via the 1921 transit link | — |
| dmz | ASA Gi0/2 | 50 | Game server host (192.168.20.10) | outside (currently unrestricted — see C-03 gap) |
| inside | ASA Gi0/0 | 100 | Trusted LAN, 192.168.10.0/24 | dmz, outside |

The asymmetry is the point: inside can initiate to the DMZ, the DMZ can never initiate to inside.

## Where NAT happens, and where it doesn't

This is the design fact that matters most and the one that caused the longest failure.

| Device | Translates? | Responsibility |
|---|---|---|
| Optimum gateway | Yes | Public IP → 1921 WAN, static forward UDP 19132 |
| Cisco 1921 | Yes | Outbound PAT overload; inbound static DNAT to the real DMZ host |
| ASA 5515-X | **No** | Routes and filters between private subnets only |

Because the ASA performs no translation, the 1921's inbound static NAT must name the actual
end host (192.168.20.10), not the ASA's outside interface. Targeting the firewall interface
produces a packet the ASA's own ACL will never match, and it dies at the implicit deny with
no log entry pointing at the cause.

## Design decisions and rejected alternatives

| Decision | Chosen | Rejected | Rationale |
|---|---|---|---|
| DMZ model | Three-legged ASA — dedicated physical interface | VLAN-based DMZ on the 2960X | A switch misconfiguration cannot merge the zones; separation happens before any filtering decision |
| Exposure model | Single-port static PAT | 1:1 NAT / ISP "DMZ host" setting | Exposes one service rather than the entire machine |
| NAT ownership | All translation on the 1921 | Split NAT across 1921 and ASA | One device owning translation makes the path traceable; split NAT doubles the failure surface |
| Server OS | Windows 11, native Bedrock `.exe` | Ubuntu Server + Docker Compose | No Linux boot option available on the host. Cost: loses nftables egress control and container isolation — recorded as the C-03 gap rather than pretended away |
| Backups | Pull from inside | Push from the DMZ host | A compromised DMZ host would otherwise hold credentials for its own backups |
| Edge router | Cisco 1921 | Cisco 891-K9 | Both EoS; the 891 adds FastEthernet LAN and no SFP — no meaningful gain |

## Evolution of the design

The build did not start here. The original plan was a router-on-a-stick design with a VLAN-based
DMZ (VLAN 20) trunked from the 2960X. Tracing the physical cabling on the ASA showed a
three-legged layout was available and strictly better, so VLAN 20 was dropped and the switch
uplink was retargeted from the router to the ASA's inside interface.

The server platform changed late: the hardening design assumed Ubuntu with nftables and a
hardened Docker Compose stack. With no Linux boot option on the host, the build moved to the
native Windows Bedrock server. That trade is documented in the table above and its consequences
are tracked as open controls in the README rather than removed from the design.
