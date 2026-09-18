# 11 — Risk Register

Likelihood and Impact rated 1 (low) – 5 (high). Score = L × I.
Treatment: Mitigate / Transfer / Avoid / Accept.

| ID | Risk | L | I | Score | Treatment | Control(s) | Status |
|---|---|---|---|---|---|---|---|
| R-01 | Router and firewall past end-of-support; no vendor security patches | 2 | 4 | 8 | **Accept** | See detail below | Accepted 2026-09-14 |
| R-02 | ISP reassigns the public address; port forward breaks | 3 | 2 | 6 | Accept | Documented dependency; re-check on failure | Accepted |
| R-03 | RCE in the game server compromises the DMZ host | 3 | 4 | 12 | Mitigate | C-02, C-08; **C-03 outstanding** | Partial |
| R-04 | Lateral movement from DMZ to trusted LAN | 2 | 5 | 10 | Mitigate | C-02, C-05 | Config present, **untested** |
| R-05 | Outbound C2 / reverse shell from a compromised DMZ host | 3 | 4 | 12 | Mitigate | C-03 | **Designed, staged — see doc 16** |
| R-06 | World data destroyed or encrypted, backups included | 2 | 4 | 8 | Mitigate | C-11 | **Not implemented** |
| R-07 | Volumetric DDoS against the exposed UDP port | 2 | 2 | 4 | Accept | ISP-dependent; QoS on the 1921 if built | Accepted |
| R-08 | Configuration drift silently opens a path | 3 | 3 | 9 | Mitigate | C-12 | **Not implemented** |
| R-09 | Faulty ASA Gi0/1 mistaken for a config fault in future work | 2 | 1 | 2 | Mitigate | Documented in 01, 05, and 14 | Mitigated |
| R-10 | Supply-chain compromise via server binary or add-ons | 2 | 4 | 8 | Mitigate | Official download source only; version tracked manually | Partial |
| R-11 | Compromised DMZ host reaches network infrastructure (ISP gateway, 1921, ASA) | 2 | 5 | 10 | Mitigate | C-03 lines 2-3 | **Designed, staged — see doc 16** |

---

## R-01 — End-of-support network hardware (ACCEPTED)

**The risk:** Both the Cisco 1921 (IOS 15.4(3)M3) and ASA 5515-X (ASA 9.3(3)) are past
end-of-support. No security patches will be issued for either, so a future vulnerability in
IOS or ASA software stays unpatched indefinitely.

**Why it was accepted rather than mitigated:** Current-generation equivalents cost multiples of
what this hardware cost on the secondhand market, and the purpose of the build is demonstrating
architecture and operational practice on real enterprise gear rather than running a business
service. The realistic exposure is bounded — neither management plane is reachable from the
internet, and the attack surface presented to the outside zone is one UDP port forwarded to a
host behind the firewall, not the firewall itself.

**Compensating controls:**
- Neither device exposes SSH, HTTP, or any management service to the outside zone.
- Management is console-based over serial, out of band from the data path.
- The explicit logged deny on `OUTSIDE-IN` records any probe against the outside interface.
- Config register verified at 0x2102, so an attacker cannot rely on a reload silently reverting
  controls.
- Config drift detection (C-12) once built will catch unauthorized change.

**Residual risk after compensating controls:** A remote pre-auth vulnerability in ASA software
reachable from the outside interface would not be patchable. This is the scenario that would
trigger replacement.

**Exit plan / review date:** Review at 12 months, or immediately if a KEV-listed vulnerability
affects ASA 9.3 or IOS 15.4 in a way reachable from the outside zone.

---

## R-05 — Outbound C2 from a compromised DMZ host (DESIGNED, STAGED)

Called out separately because it is the highest open score and the control that closes it was
the project's headline differentiator.

**The risk:** `DMZ-IN` line 2 currently permits `ip object DMZ-NET any`. A compromised game host
can reach any internet destination — establish a reverse shell, beacon to C2 infrastructure,
join a botnet, or mine cryptocurrency.

**Why it was open:** The designed implementation was nftables on Ubuntu. The host runs Windows 11
with no Linux boot option, so that implementation does not apply.

**Closure:** Fully specified in [`16-egress-filtering.md`](16-egress-filtering.md) — an ASA
egress ACL permitting DNS, NTP, and HTTPS/QUIC only, followed by a logged deny, layered with
Windows Firewall rules scoped to `bedrock_server.exe`. Staged across four phases with a rollback
path, because applying the deny in one shot breaks `online-mode=true` authentication.

**Residual risk after closure:** HTTPS-based C2 originating from the game process itself, and
DNS tunnelling through the permitted resolver. Strict destination allowlisting was evaluated and
rejected — Xbox Live spreads across rotating Microsoft and CDN addresses, so an IP allowlist
would be large, incomplete, and fail intermittently. FQDN objects were also evaluated; the
reasoning is recorded in doc 16.

Score after closure: L 2 × I 4 = **8**, down from 12.

---

## R-11 — Infrastructure reachable from the DMZ (DESIGNED, STAGED)

**The risk:** The containment rule (`DMZ-IN` line 1) covers `INSIDE-NET` only. The ISP gateway
(192.168.1.1), the 1921's transit interface (192.168.100.1), and the ASA's own outside interface
(192.168.100.2) all sit outside that object and are currently reachable from the DMZ host.

A compromised host could reach the gateway's admin interface and alter the port forward, or
probe the router and firewall that enforce every other control in this build.

**Why it went unnoticed:** `permit ip object DMZ-NET any` reads as "internet access." It is
broader than that — "any" includes the infrastructure sitting between the DMZ and the internet.
Found while writing the egress ACL, not during the build.

**Closure:** Two explicit deny lines placed above the permits, so they match first.

**Takeaway worth keeping:** a permit written to describe an intent ("let it reach the internet")
can be considerably wider than the intent. Read the rule as the device evaluates it, not as it
was meant.

---

> Accepting a risk explicitly, in writing, with compensating controls and a review date, is a
> different thing from ignoring it. Keep this page honest — it's the most credible page in the repo.
