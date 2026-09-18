# Diagrams

Keep these exact filenames so the links in the docs resolve without editing.

| Filename | Shows | Used in |
|---|---|---|
| `logical-zones.png` | **The hero image.** inside / dmz / outside, security levels, subnets. First thing a recruiter sees. | `README.md`, `docs/00-architecture.md` |
| `physical-topology.png` | Real cable runs with device and port labels | `docs/01-physical-topology.md` |
| `traffic-walkthrough.png` | Packet path for an inbound player connection | `docs/08-traffic-flows.md` |
| `packet-tracer-topology.png` | Screenshot of the simulation lab | `packet-tracer/README.md` |

## Guidelines
- PNG, 1600px wide or more — GitHub scales down, not up.
- Label every interface with both its name and its IP.
- Color-code by trust zone, and use the same colors in every diagram.
- Redact the real public IP before exporting.
- The hop-by-hop *narrative* lives in `docs/08-traffic-flows.md`, not here. Diagrams show, docs explain.

## Consistency checklist

Earlier drafts had mismatches that a reviewer will catch. Before exporting, confirm:

- [ ] Spelled "Hardened", not "Hardend"
- [ ] Model written as "2960X" everywhere, not "2960"
- [ ] The diagram title, the repo name, and the README H1 all say the same thing
- [ ] Security levels labelled on all three ASA legs — 100 / 50 / 0
- [ ] The outside leg's interface is labelled (Gi0/3, not Gi0/1 — that port is faulty)
- [ ] IP addressing present and matching `docs/03-addressing-and-vlans.md`
