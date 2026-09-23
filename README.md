# Hardened DMZ Game Server

**Defense network architecture on enterprise Cisco hardware — three-legged routed DMZ, stateful firewall enforcement, single port PAT.**

An internet-facing game server isolated from a trusted LAN by a Cisco ASA 5515-X, built on real enterprise hardware and validated end to end from an external cellular connection. Documented from cable trace to control validation, including the failures.

![Network topology](diagrams/logical-zones.png)
<!-- FILL: export the topology diagram here. This is the image a recruiter sees first. -->

---

## At a glance

| | |
|---|---|
| **Role** | Network and security design, build, hardening, documentation |
| **Edge router** | Cisco 1921 ISR — PAT overload, single-port static DNAT, static routing |
| **Firewall** | Cisco ASA 5515-X — three-legged: inside / dmz / outside |
| **Switch** | Cisco Catalyst WS-C2960X-48LPS-L — trusted-side layer 2 |
| **Server host** | Intel i3-13100F (4 cores, 8 threads) / 24 GB RAM / 256 TB SSD — Windows 11 |
| **Exposed service** | Minecraft Bedrock — UDP 19132, single-port static PAT |
| **Users served** | ~5 allowlisted players |
| **Status** | **Core build validated end to end.** Egress filtering and backup automation outstanding — see [control status](#security-controls) |

---

## The problem

Running a game server for friends normally means enabling a port forward on the ISP router and pointing it at a desktop on the home LAN. That desktop then sits on the same flat network as everything else — personal files, other machines, the router's own management interface.

Minecraft servers are a real target, not a theoretical one. Log4Shell (CVE-2021-44228) was exploited in the wild through Minecraft chat messages, turning a game server into remote code execution. On a flat network, that compromise reaches everything.

The goal for this build was not to prevent that compromise. It was to assume it happens and make sure the attacker's next step fails.

## The approach

Treat the game host as untrusted from the first cable. Put it on its own physical firewall interface so the trusted LAN is never one misconfiguration away. Make the exposed surface exactly one UDP port on exactly one host. Deny the DMZ-to-inside path explicitly and log it, so a pivot attempt is both blocked and recorded. Then prove each control works rather than assuming it does.

---

## Architecture

```
Internet
   │  UDP 19132
   ▼
[ Optimum ONT — Altice GR140IG ]   static forward → 1921 WAN
   │
   ▼
[ Cisco 1921 ISR — edge-rtr-01 ]   Gi0/0 outside  192.168.1.147   (ip nat outside)
   │                               Gi0/1 transit  192.168.100.1/30 (ip nat inside)
   │                               PAT overload + static DNAT → 192.168.20.10
   │                               static route 192.168.20.0/24 → 192.168.100.2
   ▼
[ Cisco ASA 5515-X — ASA-FW-01 ]   Gi0/3 outside  192.168.100.2/30   level 0
   ├── Gi0/0 inside  192.168.10.1/24   level 100  → Catalyst 2960X
   └── Gi0/2 dmz     192.168.20.0/24   level 50   → game server host
```

The ASA performs no NAT. It routes and filters between private subnets while the 1921 owns every translation. That division is the single most important design fact in this repo — it determines what the inbound static NAT must target, and getting it wrong is [failure #2](docs/14-troubleshooting-log.md).

| Document | Covers |
|---|---|
| [`docs/00-architecture.md`](docs/00-architecture.md) | Design principles, zone model, rejected alternatives |
| [`docs/01-physical-topology.md`](docs/01-physical-topology.md) | Port mapping, cable trace, why three-legged |
| [`docs/03-addressing-and-vlans.md`](docs/03-addressing-and-vlans.md) | Every IP, subnet, and port — single source of truth |
| [`docs/08-traffic-flows.md`](docs/08-traffic-flows.md) | Hop-by-hop verdict for every permitted and denied flow |

---

## Security controls

| # | Control | Enforced at | Status | Why it matters |
|---|---|---|---|---|
| C-01 | Single-port static PAT (UDP 19132 only) | Cisco 1921 | **Implemented, verified** | Exposes one service, not one host. |
| C-02 | DMZ → inside deny + log | ASA `DMZ-IN` | **Implemented, untested** | A compromised game host cannot pivot to the trusted LAN. |
| C-03 | Default-deny egress from the DMZ | ASA `DMZ-IN` + host | **Designed, staged rollout ready** | Blocks reverse shells, non-HTTPS C2, and all infrastructure access. Runbook: [`docs/16-egress-filtering.md`](docs/16-egress-filtering.md) |
| C-04 | Explicit deny + log on untrusted interface | ASA `OUTSIDE-IN` | **Implemented, verified** | Turns scan traffic into evidence instead of silence. |
| C-05 | Dedicated physical DMZ leg | ASA Gi0/2 | **Implemented, verified** | No shared switch fabric; VLAN hopping is out of the threat path. |
| C-06 | Stateful inspection | ASA 5515-X | **Implemented, verified** | Return traffic permitted only for legitimate sessions. |
| C-07 | L2 hardening | Catalyst 2960X | **Not confirmed applied** | Unused-port shutdown, DTP off, BPDU guard, management VLAN. |
| C-08 | Application-layer authentication | Bedrock server | **Implemented, verified** | Xbox Live auth + allowlist: reaching the port ≠ reaching the game. |
| C-09 | Host firewall exception, not disable | Windows 11 | **Implemented** | One inbound UDP rule instead of turning the firewall off. |
| C-10 | Config persistence verified | Cisco 1921 | **Implemented, verified** | Register 0x2102, proven by reload — controls survive a power event. |
| C-11 | Pull-based backups | Backup host (inside) | **Not implemented** | Designed; DMZ host would hold no backup credentials. |
| C-12 | Config backup + drift detection | `scripts/` | **Not implemented** | A silent rule change should be caught, not discovered mid-incident. |

Implementation detail with exact commands: [`docs/09-hardening-baseline.md`](docs/09-hardening-baseline.md)

### Known gaps

**C-03 is designed and ready to apply, but not yet live on the device.** The original implementation was nftables on Ubuntu; the host runs Windows 11, so the control moved to an ASA egress ACL plus process-scoped Windows Firewall rules. The full ACL, a staged four-phase rollout, and a rollback path are in [`docs/16-egress-filtering.md`](docs/16-egress-filtering.md). It is staged rather than applied in one shot because a deny-all egress breaks `online-mode=true` authentication, and that failure presents as a game bug rather than a firewall rule.

Residual risk after C-03 is applied: HTTPS-based C2 from the game process itself, and DNS tunnelling through the permitted resolver. Both are recorded in R-05 rather than claimed as covered.

**C-07, C-11, C-12 are designed but not built.** Marked honestly above rather than left as unfilled placeholders.

---

## Validation

| Test | Claim proven | Result | Evidence |
|---|---|---|---|
| T-01 | Service reachable from the internet | **PASS** | [`evidence/external-connectivity-test.png`](evidence/) |
| T-02 | Config survives reload | **PASS** | [`evidence/config-register.png`](evidence/) |
| T-03 | Inside zone reaches the internet | **PASS** | [`evidence/inside-egress.png`](evidence/) |
| T-04 | DMZ zone reaches the internet | **PASS** | [`evidence/dmz-egress.png`](evidence/) |
| T-05 | External UDP reaches the DMZ host | **PASS** | [`evidence/udp-listener-external.png`](evidence/) |
| T-06 | End-to-end game session from outside | **PASS** | [`evidence/bedrock-player-connected.png`](evidence/) |
| T-07 | DMZ cannot reach the trusted LAN | *Not yet run* | — |
| T-08 | Only UDP 19132 exposed | *Not yet run* | — |
| T-09 | ACLs matching real traffic | *Capture pending* | — |

Full matrix and commands: [`docs/13-validation-tests.md`](docs/13-validation-tests.md)

---

## Repo map

```
docs/           Architecture, per-device build docs, baseline, risk register, validation
diagrams/       Topology and zone diagrams
configs/        Sanitized device and host configurations
scripts/        Backup pull, device config backup, drift detection, egress validation
packet-tracer/  Simulation lab mirroring the physical build
evidence/       Screenshots and output backing every validation claim
```

---

## Skills demonstrated

Network segmentation · DMZ architecture · Cisco IOS and ASA configuration · NAT and PAT · destination NAT troubleshooting · static routing · stateful firewall ACL design · layer 2 hardening · Windows host hardening · risk register and control documentation · CVE triage and patch management (CISA KEV + EPSS) · structured fault isolation

---

## Accepted risks

**R-01 — Edge router and firewall are past end-of-support.** No vendor security patches are available for the 1921 or ASA 5515-X. Accepted with compensating controls and a documented review trigger: [`docs/11-risk-register.md`](docs/11-risk-register.md)

---

## What broke, and how it was found

Six real failures, each isolated to a specific device before anything was changed: a configuration register silently discarding every edit, an inbound NAT rule pointed at a firewall interface instead of the host behind it, a missing return route, an ISP cable patched past every security control, a "factory default" firewall that wasn't, and a server binary exiting with no output at all.

[`docs/14-troubleshooting-log.md`](docs/14-troubleshooting-log.md)
