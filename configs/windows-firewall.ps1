# =============================================================
# Windows Defender Firewall — game server host (DMZ)
# Host      : Windows 11, 192.168.20.10
# Build doc : docs/07-host-hardening.md
#
# Principle : add an exception, never disable the firewall.
#             Disabling it to "make it work" removes the host layer
#             entirely and is the most common shortcut in this kind
#             of build.
# =============================================================

# --- INBOUND: implemented and verified ---

New-NetFirewallRule `
  -DisplayName "Minecraft Bedrock" `
  -Direction Inbound `
  -Protocol UDP `
  -LocalPort 19132 `
  -Action Allow

# Verify:
#   Get-NetFirewallRule -DisplayName "Minecraft Bedrock" | Format-List
#   netstat -an | Select-String "19132"


# =============================================================
# --- OUTBOUND: process scoping (C-03, phase 4) ---
#
# The ASA restricts protocol and destination. It cannot tell
# bedrock_server.exe from a dropped payload using the same port.
# Windows can. That is the actual argument for running both.
#
# Apply AFTER the ASA rules in docs/16-egress-filtering.md.
# =============================================================

New-NetFirewallRule `
  -DisplayName "Bedrock - outbound HTTPS (TCP)" `
  -Direction Outbound `
  -Program "C:\McServer\bedrock_server.exe" `
  -Protocol TCP `
  -RemotePort 443 `
  -Action Allow

New-NetFirewallRule `
  -DisplayName "Bedrock - outbound QUIC (UDP)" `
  -Direction Outbound `
  -Program "C:\McServer\bedrock_server.exe" `
  -Protocol UDP `
  -RemotePort 443 `
  -Action Allow


# --- Flipping the default: a deliberate decision, not a default ---
#
# Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block
#
# This is disruptive. Windows Update, activation, and telemetry all stop
# until explicitly permitted.
#
#   Flip it  : this is a DMZ host, it should do one job, and anything that
#              breaks was something you did not know was running.
#   Leave it : the ASA already enforces; these rules scope the process.
#              Enforcement should not depend on the host that might be
#              compromised.
#
# Recommendation: enforce at the ASA, scope at the host, leave the Windows
# default at allow until there is a reason. The ASA rule survives a
# compromised host. A host rule does not.
#
# If you do flip it, log denials while tuning:
# Set-NetFirewallProfile -Profile Public -LogBlocked True `
#   -LogFileName "C:\McServer\fw-blocked.log"


# --- Verify ---
#   Get-NetFirewallRule -DisplayName "Bedrock*" | Format-List DisplayName,Direction,Action
#   Get-NetFirewallProfile | Select-Object Name,DefaultOutboundAction
#   .\validate-egress.ps1
