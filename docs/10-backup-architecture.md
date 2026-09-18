# 10 — Backup Architecture

Script: [`../scripts/pull-backup.ps1`](../scripts/pull-backup.ps1)
Status: **designed, not implemented** (C-11)

## Why pull, and why push would be wrong

A push model requires the DMZ host to hold credentials for, and network reach to, the backup
target. Compromise the game host and the attacker owns the backups too — which is exactly the
scenario backups exist for. Ransomware operators specifically hunt for reachable backup shares
before encrypting, because destroying the recovery path is what converts an incident into a
payment.

Pulling inverts the trust direction. The backup host initiates, the DMZ host holds no
credentials, and `DMZ-IN` line 1 means it could not reach the archive even if it did.

## Architecture

```
[ Backup host — inside zone ] ──initiates──► [ Game server host — DMZ ]
          │                                            │
          └─ archive stored on <TARGET>          (no backup creds,
                                                  cannot reach inside)
```

| Item | Value |
|---|---|
| Backup host | `<HOSTNAME / IP>` (inside, 192.168.10.0/24) |
| Transport | `<FILL — e.g. SMB read-only share, or SSH if OpenSSH Server is installed>` |
| Credential direction | Backup host → server host only |
| Source path | `C:\McServer\worlds\` |
| Schedule | `<FILL>` |
| Retention | `<FILL — e.g. 7 daily, 4 weekly, 3 monthly>` |
| Archive location | `<FILL>` |
| Second copy / offsite | `<FILL, or "none — accepted risk">` |
| Encryption at rest | `<FILL>` |

## ASA rule this requires

The inside → dmz path must permit the backup host to the server on the transport port, and
nothing else. Write it as a named source, not a subnet:

```
access-list INSIDE-IN extended permit tcp host <BACKUP_HOST> object MC-SERVER eq <PORT>
```

## Consistency

A Bedrock world is a LevelDB database under continuous write. Copying it live produces a
backup that may or may not open — a coin flip discovered only at restore time.

Options, in order of preference:
1. Stop the server, copy, restart. Simple and correct; costs downtime.
2. Use the console `save hold` / `save query` / `save resume` sequence to quiesce writes,
   copy while held, then resume.
3. Volume Shadow Copy Service snapshot, then copy from the snapshot.

`<FILL: pick one and document the exact sequence.>`

## Restore procedure

1. `<FILL>`
2. `<FILL>`
3. `<FILL>`
4. `<FILL>`

| Metric | Target | Last tested | Actual |
|---|---|---|---|
| RPO — max data loss | `<FILL>` | — | — |
| RTO — time to restore | `<FILL>` | — | — |

## Restore test log

| Date | Archive tested | Result | Notes |
|---|---|---|---|
| — | — | — | Not yet tested |

An untested backup is not a backup. Do at least one real restore before calling this done.
