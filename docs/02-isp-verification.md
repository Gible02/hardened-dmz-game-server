# 02 — ISP Verification

> Done before any design work. Everything downstream depends on actually owning a
> routable public address.

## Why this comes first

If the ISP places the connection behind carrier-grade NAT, inbound port forwarding is
impossible and the entire exposure model has to change — a tunnel broker instead of a
routed DMZ. Verifying this first avoided designing around an assumption.

## Circuit details

| Item | Value |
|---|---|
| ISP | Optimum |
| Media | Fiber |
| ONT / gateway | Altice GR140IG |
| Plan type | Residential |
| DHCP reservation available? | No — the 1921's WAN interface was set static instead |
| 1921 WAN address | 192.168.1.147 (behind the Optimum gateway) |
| Port forward | UDP 19132 → 192.168.1.147, configured by ISP phone support |

## CGNAT check

**Method:** traceroute from inside the network, inspecting hop 2.

**Result:** A public Optimum address appeared at hop 2, immediately past the gateway — no
carrier-grade NAT in path.

```
<FILL: paste the sanitized traceroute output — redact your real public IP>
```

Evidence: [`../evidence/traceroute-public-ip.png`](../evidence/)

**Conclusion:** Direct inbound port forwarding is viable. No tunnel workaround
(Playit.gg or similar) required.

## Dependency this creates

The public address is not contractually static on a residential plan. If Optimum reassigns it,
the forward breaks and external clients fail with no change on any device in this repo. Tracked
as R-02 in [`11-risk-register.md`](11-risk-register.md).

## What would have changed if CGNAT had been present

The exposure model would have moved to an outbound-only tunnel — the server initiates a
connection to a relay, and players connect to the relay instead. That removes the inbound
firewall rule entirely but adds a third-party dependency in the data path and loses the
ability to demonstrate ACL and NAT design, which is the point of this build.
