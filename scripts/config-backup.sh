#!/usr/bin/env bash
# =============================================================
# config-backup.sh
# RUNS ON : management host, inside zone.
# Purpose : scheduled pull of running configs from all network devices,
#           sanitized and stored for drift comparison. (C-12 / R-08)
# =============================================================
set -euo pipefail

BACKUP_DIR="<CONFIG_ARCHIVE_PATH>"
STAMP="$(date +%Y%m%d)"
DEST="${BACKUP_DIR}/${STAMP}"

# device -> address
declare -A DEVICES=(
  [cisco-1921]="<MGMT_IP_1921>"
  [asa-5515x]="<MGMT_IP_ASA>"
  [catalyst-2960x]="<MGMT_IP_2960X>"
)

mkdir -p "$DEST"

for name in "${!DEVICES[@]}"; do
  host="${DEVICES[$name]}"
  echo "pulling ${name} (${host})"

  # <FILL: pull the running config. Options:
  #   - ssh with a read-only account running 'show running-config'
  #   - scp/tftp export
  #   - netmiko if the device needs interactive handling
  # Use a credential scoped to read-only. A backup job should not be able
  # to change config. >

  # <FILL: run it through the sanitizer from docs/15-sanitization.md before it
  #        lands on disk — this archive may end up in git, so the ASA serial
  #        and the enable password hash must never enter it. >
done

# <FILL: prune archives older than <N> days>
# <FILL: call config-diff.sh and alert if drift is found>
