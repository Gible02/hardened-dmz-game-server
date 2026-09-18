# 08 — Traffic Flows

> For each flow: the path, every enforcement point it crosses, and the verdict at each one.
> This is the page interviewers pull on.

## Flow 1 — Player connects from the internet (ALLOWED, verified)

| Hop | Device | Rule / mechanism | Verdict |
|---|---|---|---|
| 1 | Optimum ONT | Static port forward UDP 19132 → 192.168.1.147 | Forward |
| 2 | Cisco 1921 | `ip nat inside source static udp 192.168.20.10 19132 interface Gi0/0 19132` | Translate destination to the real host |
| 3 | Cisco 1921 | `ip route 192.168.20.0 255.255.255.0 192.168.100.2` | Route to ASA outside |
| 4 | ASA outside | `OUTSIDE-IN` line 1 — `permit udp any object MC-SERVER eq 19132` | Permit, create state entry |
| 5 | ASA dmz | Forwarded out Gi0/2 | Deliver to segment |
| 6 | Windows firewall | Inbound rule, UDP 19132 | Accept |
| 7 | `bedrock_server.exe` | Xbox Live auth, then allowlist check | Admit or reject the player |

**Verified:** an external Bedrock client on cellular connected, authenticated, and spawned.
Server log recorded connect, party update, spawn, and disconnect.

Note that hops 6 and 7 are not redundant with hops 4 and 5. The firewall decides whether the
packet arrives; the application decides whether the person is allowed in. A stolen network path
still faces an authentication wall.

## Flow 2 — Server host reaches out to the internet (DEFAULT-DENY, staged)

| Hop | Device | Rule | Verdict |
|---|---|---|---|
| 1 | Windows firewall | Outbound rules scoped to `bedrock_server.exe` | Permit named process only |
| 2 | ASA dmz → outside | `DMZ-IN` lines 4-7 — DNS, NTP, HTTPS/QUIC only | Permit named exceptions |
| 3 | ASA dmz → outside | `DMZ-IN` line 8 — `deny ip any any log` | Everything else: deny + log |
| 4 | Cisco 1921 | `NAT-SOURCES` PAT overload | Translate source |

Permitted exceptions, each with a reason it cannot be removed:

| Destination | Port | Why required |
|---|---|---|
| Chosen DNS resolver | UDP 53 | Resolving Microsoft auth hostnames |
| Time source | UDP 123 | Certificate validation fails on clock skew |
| Any, HTTPS | TCP 443 | Xbox Live auth and the Minecraft signaling service |
| Any, QUIC | UDP 443 | Microsoft services use HTTP/3; failing closed to TCP is slow |

**Status: designed and staged, not yet applied.** Runbook, rollout phases, and rollback in
[`16-egress-filtering.md`](16-egress-filtering.md). Applied in one shot, this breaks
`online-mode=true` and the failure looks like a game bug.

**What it stops once live:** reverse shells on arbitrary ports, non-HTTPS C2, SMB/RDP/SSH egress,
most cryptominers, and all access to the ISP gateway, the 1921, and the ASA itself.

**What it does not stop:** HTTPS-based C2 originating from the game process, and DNS tunnelling
through the permitted resolver. Recorded as residual risk in R-05.

## Flow 3 — Server host → trusted LAN (DENIED)

| Hop | Device | Rule | Verdict |
|---|---|---|---|
| 1 | ASA dmz → inside | `DMZ-IN` line 1 — `deny ip object DMZ-NET object INSIDE-NET log` | Deny + log |

**The control that matters most.** A compromised game host attempting to reach 192.168.10.0/24
is dropped at the firewall and recorded with source and destination. The attacker is confined
to a single-host segment.

**Status: implemented, not yet tested.** Run T-07 and capture the hit counter before claiming
this works. An untested deny rule is an assumption.

Proof pending: [`../evidence/dmz-to-inside-denied.png`](../evidence/)

## Flow 4 — Inside zone to the internet (ALLOWED, verified)

| Hop | Device | Rule | Verdict |
|---|---|---|---|
| 1 | ASA inside → outside | Higher security level to lower, stateful | Permit |
| 2 | Cisco 1921 | `NAT-SOURCES` PAT overload | Translate source |
| 3 | Optimum gateway | Second translation to the public IP | Forward |

**Verified:** a client on the 2960X pulled a DHCP lease from the ASA and reached 8.8.8.8.

## Flow 5 — Backup pull, inside → DMZ (DESIGNED, not built)

| Hop | Device | Rule | Verdict |
|---|---|---|---|
| 1 | ASA inside → dmz | `<ACL LINE — permit from backup host only>` | Permit named source only |
| 2 | Windows firewall | `<RULE — accept from backup host only>` | Accept |

Note the asymmetry — it is the whole reason the backup model is pull rather than push. The DMZ
host never initiates and holds no backup credentials, so compromising it does not compromise
the archive.

## Flow 6 — Administrative access

| Hop | Device | Rule | Verdict |
|---|---|---|---|
| 1 | Console (serial) | Physical access to 1921 and ASA | Out-of-band by design |
| 2 | `<MGMT_HOST>` → devices | `<FILL: SSH restricted by source>` | `<FILL>` |

Device management is currently console-based over serial. Neither the 1921 nor the ASA exposes
a management interface to the outside zone.
