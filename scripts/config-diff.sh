#!/usr/bin/env bash
# =============================================================
# config-diff.sh
# RUNS ON : management host, inside zone.
# Purpose : compare the latest config pull against the last known-good
#           baseline and report any change. (C-12 / R-08)
#
# A rule that changed without a matching commit is either a mistake
# or an intrusion. Either way you want to know on a schedule, not
# during an incident.
# =============================================================
set -uo pipefail

BACKUP_DIR="<CONFIG_ARCHIVE_PATH>"
BASELINE="${BACKUP_DIR}/baseline"
LATEST="$(ls -1d "${BACKUP_DIR}"/20* 2>/dev/null | tail -1)"

[ -n "${LATEST:-}" ] || { echo "no config pulls found"; exit 1; }

DRIFT=0

for file in "${BASELINE}"/*; do
  name="$(basename "$file")"
  new="${LATEST}/${name}"

  if [ ! -f "$new" ]; then
    echo "[WARN] ${name}: no current pull — device unreachable?"
    DRIFT=1
    continue
  fi

  # <FILL: strip volatile lines before diffing — NVRAM checksums, uptime,
  #        timestamps, and ACL hit counters change every pull and are not drift.
  #        On the ASA specifically, the Cryptochecksum line changes on every
  #        write and will produce a false positive. >

  if diff -u "$file" "$new" > /tmp/"${name}".diff 2>&1; then
    echo "[OK]   ${name}: no drift"
  else
    echo "[DRIFT] ${name}:"
    cat /tmp/"${name}".diff
    DRIFT=1
  fi
done

# <FILL: on drift — alert, and decide whether to promote the new config to
#        baseline (intended change) or investigate (unintended). Never auto-promote. >

exit "$DRIFT"
