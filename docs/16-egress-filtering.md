# 16 — Egress Filtering (C-03)

> Closes the gap recorded as **R-05**. Follow the phases in order. Applying the
> final deny without the discovery phase will break `online-mode=true` and the
> failure will look like a game bug rather than a firewall rule.

## What this control actually buys

A compromised game host is only useful to an attacker if it can talk back out. Every
post-exploitation step — pulling a second-stage payload, opening a reverse shell, beaconing to
C2, joining a botnet, mining — requires outbound reachability. `DMZ-IN` line 2 currently reads
`permit ip object DMZ-NET any`, so all of that works today.

There is a second problem hiding in that same line. Unrestricted egress does not just mean the
internet — it means the DMZ host can currently reach:

| Destination | What it is | Why that matters |
|---|---|---|
| 192.168.1.1 | Optimum gateway admin interface | Change the port forward, expose more of the network |
| 192.168.100.1 | Cisco 1921 transit interface | Reach the router that owns all NAT |
| 192.168.100.2 | ASA outside interface | Reach the firewall enforcing containment |

The containment rule (`DMZ-IN` line 1) only covers `INSIDE-NET`. Infrastructure addresses sit
outside that object and are reachable. Closing this is arguably more valuable than the internet
side, and it costs two lines.

## The honest constraint

Strict destination allowlisting does not work cleanly here. Xbox Live authentication resolves to
a wide, rotating set of Microsoft and CDN addresses. An IP-based allowlist would need thousands
of prefixes and would break on every Microsoft range update.

So this design enforces at two layers, each doing what the other cannot:

| Layer | Restricts by | Catches |
|---|---|---|
| ASA `DMZ-IN` | Protocol, port, destination | Reverse shells on arbitrary ports, non-HTTPS C2, SMB/RDP/SSH egress, most miners, all infrastructure access |
| Windows Defender Firewall | **Which executable** | Anything that isn't `bedrock_server.exe` trying to egress at all |

The ASA cannot see process identity. The host firewall can. Neither alone is sufficient, which
is the actual argument for defense in depth rather than the usual hand-waving version.

**What this still does not stop:** HTTPS-based C2 originating from the game process itself, and
DNS tunnelling through the permitted resolver. Both are recorded honestly in R-05 as residual
risk rather than claimed as covered.

---

## Phase 1 — Discovery

Find out what the server actually talks to before restricting anything. Run this on the ASA
while the server is up, and again with a player connected:

```
show conn address 192.168.20.10
```

Repeat across a few minutes and a player join. Record every distinct destination and port. You
are looking to confirm the expectation below, and to catch anything unexpected:

| Expected | Port | Why |
|---|---|---|
| DNS resolver | UDP 53 | Resolving Microsoft auth hostnames |
| Microsoft auth / signaling | TCP 443 | `online-mode=true`, the signaling service seen at startup |
| Microsoft services | UDP 443 | QUIC / HTTP3 — Microsoft uses it, and it fails closed to TCP slowly |
| Time source | UDP 123 | Certificate validation fails on clock skew |

Note the DNS server the host is actually using (`ipconfig /all` on the server, or the `dhcpd dns`
value if it were DHCP — this host is static, so check the NIC).

---

## Phase 2 — Stage the permits, keep the escape hatch

Insert specific rules **above** the existing `permit ip object DMZ-NET any`. Nothing breaks yet,
because the permit-any is still there catching anything you missed.

```
! --- infrastructure protection: the DMZ has no business here ---
access-list DMZ-IN line 2 extended deny ip object DMZ-NET host 192.168.1.1 log informational interval 300
access-list DMZ-IN line 3 extended deny ip object DMZ-NET 192.168.100.0 255.255.255.252 log informational interval 300

! --- name resolution ---
access-list DMZ-IN line 4 extended permit udp object DMZ-NET host <DNS_SERVER> eq domain

! --- time: cert validation fails on clock skew ---
access-list DMZ-IN line 5 extended permit udp object DMZ-NET host <NTP_SERVER> eq ntp

! --- Xbox Live auth, Minecraft signaling, Windows Update: all HTTPS ---
access-list DMZ-IN line 6 extended permit tcp object DMZ-NET any eq https
access-list DMZ-IN line 7 extended permit udp object DMZ-NET any eq 443
```

Then verify the traffic is matching your new rules rather than falling through to the catch-all:

```
show access-list DMZ-IN
```

Lines 4–7 should be incrementing. **Line 8 (`permit ip object DMZ-NET any`) should be at or near
zero.** If it is climbing, something is still using a path you have not named — go back to
`show conn` and find it before continuing.

Let this sit through at least one full player session.

---

## Phase 3 — Remove the escape hatch

Only once line 8 has stopped incrementing:

```
no access-list DMZ-IN extended permit ip object DMZ-NET any
access-list DMZ-IN extended deny ip any any log informational interval 300
write memory
```

The explicit logged deny matters for the same reason it does on `OUTSIDE-IN`: the implicit deny
is silent, and a silent block during an incident tells you nothing.

### Final ACL

```
access-list DMZ-IN line 1 extended deny ip object DMZ-NET object INSIDE-NET log informational interval 300
access-list DMZ-IN line 2 extended deny ip object DMZ-NET host 192.168.1.1 log informational interval 300
access-list DMZ-IN line 3 extended deny ip object DMZ-NET 192.168.100.0 255.255.255.252 log informational interval 300
access-list DMZ-IN line 4 extended permit udp object DMZ-NET host <DNS_SERVER> eq domain
access-list DMZ-IN line 5 extended permit udp object DMZ-NET host <NTP_SERVER> eq ntp
access-list DMZ-IN line 6 extended permit tcp object DMZ-NET any eq https
access-list DMZ-IN line 7 extended permit udp object DMZ-NET any eq 443
access-list DMZ-IN line 8 extended deny ip any any log informational interval 300
```

Deny rules first, permits second, logged deny last. Order is not cosmetic — ASA evaluates
top-down and stops at the first match, so the infrastructure denies must precede the broad
HTTPS permit or they will never fire.

---

## Phase 4 — Host layer: process scoping

The ASA cannot tell `bedrock_server.exe` from a dropped payload using the same port. Windows can.

```powershell
# Permit the game server explicitly
New-NetFirewallRule -DisplayName "Bedrock - outbound HTTPS (TCP)" `
  -Direction Outbound -Program "C:\McServer\bedrock_server.exe" `
  -Protocol TCP -RemotePort 443 -Action Allow

New-NetFirewallRule -DisplayName "Bedrock - outbound QUIC (UDP)" `
  -Direction Outbound -Program "C:\McServer\bedrock_server.exe" `
  -Protocol UDP -RemotePort 443 -Action Allow
```

**Then decide, deliberately, whether to flip the default:**

```powershell
# Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block
```

This is disruptive. Windows Update, activation, and telemetry all stop until explicitly
permitted, and you will be adding rules for a while. Two defensible positions:

| Choice | Argument |
|---|---|
| Flip it | This is a DMZ host. It should do one job. Anything that breaks was something you did not know was running, which is the point |
| Leave it | The ASA is already enforcing; host rules scope the game process. Lower operational cost, and the enforcement does not depend on the host that might be compromised |

If you flip it, log denials while tuning so you can see what you broke:

```powershell
Set-NetFirewallProfile -Profile Public -LogBlocked True -LogFileName "C:\McServer\fw-blocked.log"
```

**Recommendation:** enforce at the ASA, scope at the host, leave the Windows default at allow
until you have a reason. The ASA rule survives a compromised host; a host rule does not.

---

## Tighter alternative, and why it was not used

ASA 9.3 supports FQDN network objects:

```
object network XBOX-AUTH
 fqdn login.live.com
```

This requires `dns domain-lookup` on an interface and a configured DNS server group, resolves on
a TTL, and matches only exact names. Xbox Live spreads across many rotating hostnames behind
CDNs, so the object set would be large, incomplete, and would fail intermittently as names
rotate — producing authentication failures that look like game bugs.

Recorded here because "I evaluated the tighter control and rejected it for a stated reason" is a
stronger position than not knowing the feature exists.

---

## Validation

Update **T-12** in [`13-validation-tests.md`](13-validation-tests.md) once this is in.

```
# On the DMZ host — should now FAIL
Test-NetConnection 8.8.8.8 -Port 53
Test-NetConnection <ARBITRARY_HOST> -Port 4444
Test-NetConnection 192.168.1.1 -Port 80

# Should still SUCCEED
Test-NetConnection login.live.com -Port 443
Resolve-DnsName minecraft.net

# On the ASA — confirm the denies are firing and being recorded
show access-list DMZ-IN
show logging | include DMZ-IN
```

**The real test:** have a player disconnect and reconnect. If `online-mode=true` authentication
still succeeds, the permits are correct. If it hangs or rejects, DNS or HTTPS is over-restricted —
check line 8's counter, it will tell you what you blocked.

`scripts/validate-egress.ps1` automates most of the above and currently fails by design until
this control is in place.

## Rollback

If authentication breaks and you need the server up immediately:

```
access-list DMZ-IN line 8 extended permit ip object DMZ-NET any
```

That restores the catch-all above the final deny. Diagnose from the hit counters, fix the
specific permit, then remove it again. Do not leave it in place — it is the gap this whole
document exists to close.
