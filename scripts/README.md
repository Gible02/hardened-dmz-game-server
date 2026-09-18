# Scripts

| Script | Runs on | Purpose | Status |
|---|---|---|---|
| `pull-backup.ps1` | Backup host (inside) | Pulls world data from the DMZ host. The DMZ host never initiates and holds no credentials. | Skeleton |
| `config-backup.sh` | Management host (inside) | Scheduled pull of running configs from the 1921, ASA, and 2960X. | Skeleton |
| `config-diff.sh` | Management host (inside) | Diffs today's configs against the last known-good set. Drift detection (C-12, R-08). | Skeleton |
| `validate-egress.ps1` | Game server host (DMZ) | Proves egress filtering and DMZ containment are holding. | Skeleton |

All four are skeletons. Fill the marked sections and test before trusting them.

**Why config backup and drift detection are here:** a firewall rule that changes without a
corresponding commit is either a mistake or an intrusion. Catching it on a schedule beats
discovering it during an incident.

**Note:** `validate-egress.ps1` will currently report failures on the egress section, because
default-deny egress is not implemented (C-03). That is the correct result — the script is
written to fail loudly on an unenforced control rather than skip it.
