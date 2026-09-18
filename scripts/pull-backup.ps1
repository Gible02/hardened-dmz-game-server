# =============================================================
# pull-backup.ps1
# RUNS ON     : the backup host, inside the trusted zone.
# DOES NOT RUN: on the DMZ game server host.
#
# Why: a push model needs the DMZ host to hold credentials for and reach the
# backup target. Compromise the game host, own the backups. Pull inverts that.
# See docs/10-backup-architecture.md
# =============================================================

$ErrorActionPreference = "Stop"

$SrcHost    = "192.168.20.10"
$SrcShare   = "<REMOTE_WORLD_PATH>"       # e.g. \\192.168.20.10\McServerWorlds
$Dest       = "<LOCAL_ARCHIVE_PATH>"
$RetainDays = <N>
$LogPath    = "<LOG_PATH>"

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Write-Log($Message) {
    $line = "{0}  {1}" -f (Get-Date -Format o), $Message
    $line | Tee-Object -FilePath $LogPath -Append
}

# --- preflight ---
# <FILL: verify $Dest exists and has free space; bail loudly if not>

# --- quiesce so the world isn't captured mid-write ---
# A Bedrock world is a LevelDB database under continuous write. Copying it
# live produces a backup that may or may not open — discovered only at restore.
# Pick one and implement it:
#   1. Stop the server, copy, restart.       (simple, correct, costs downtime)
#   2. Console: save hold / save query / save resume.
#   3. VSS snapshot, then copy from the shadow copy.
# <FILL>

Write-Log "starting pull from $SrcHost"

# --- transfer ---
# <FILL: robocopy "$SrcShare" "$Dest\current" /MIR /R:2 /W:5 /LOG+:$LogPath
#        or an SSH/scp equivalent if OpenSSH Server is installed on the host >

# --- snapshot ---
# <FILL: Compress-Archive "$Dest\current\*" "$Dest\archive\world-$Stamp.zip" >

# --- verify ---
# <FILL: non-zero size AND an integrity check — open the archive, or compare
#        a checksum against the source. An unverified backup is a guess. >

# --- prune ---
# <FILL: remove archives older than $RetainDays >

Write-Log "pull complete: world-$Stamp.zip"

# --- notify on failure ---
# <FILL: a silent backup failure is worse than no backup — you'll believe you have one. >
