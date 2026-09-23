# Packet Tracer Lab

A simulation of the physical build, used to test config changes before touching live gear.

![Packet Tracer topology](../diagrams/packet-tracer-topology.png)

| File | Covers |
|---|---|
| `dmz-lab.pkt` | `<FILL: what this version of the lab includes>` |

## Device substitutions

Packet Tracer doesn't carry the exact models in the physical build:

| Physical | Simulated | What doesn't carry over |
|---|---|---|
| Cisco 1921 ISR | 1941 ISR | `<FILL>` |
| ASA 5515-X | ASA 5506-X | `<FILL: syntax and feature differences hit in practice>` |
| Catalyst 2960X-48LPS-L | `<MODEL>` | `<FILL>` |

## What the sim proved
- [ ] `<FILL: e.g. ACL ordering on the DMZ interface>`
- [ ] `<FILL: e.g. NAT behavior before committing to the 1921>`

## What the sim could not prove

The faulty Gi0/1 port, real ISP behaviour, the config-register fault, the missing Visual C++
runtime, and actual UDP game traffic from an external network. Every one of the six failures in
[`../docs/14-troubleshooting-log.md`](../docs/14-troubleshooting-log.md) came from the physical
build, not the simulation.

Stating the limits of your own simulation is a maturity signal. Don't skip this section.

## Opening it
Cisco Packet Tracer `<VERSION>` or later.
