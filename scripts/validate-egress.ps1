# =============================================================
# validate-egress.ps1
# RUNS ON : the DMZ game server host (Windows 11, 192.168.20.10).
# Purpose : prove DMZ containment (C-02) and egress filtering (C-03)
#           are actually holding. Run after every ACL or firewall change.
#           Paste the output into evidence/.
#
# EXPECT FAILURES on the egress section today — C-03 is not implemented.
# The script is written to fail loudly on an unenforced control rather
# than skip it. See docs/11-risk-register.md R-05.
# =============================================================

$Pass = 0
$Fail = 0

function Test-Blocked {
    param([string]$Name, [scriptblock]$Check)
    $result = & $Check
    if ($result) {
        Write-Host "[FAIL] $Name - succeeded, should have been BLOCKED" -ForegroundColor Red
        $script:Fail++
    } else {
        Write-Host "[PASS] $Name - blocked" -ForegroundColor Green
        $script:Pass++
    }
}

function Test-Allowed {
    param([string]$Name, [scriptblock]$Check)
    $result = & $Check
    if ($result) {
        Write-Host "[PASS] $Name - reachable as designed" -ForegroundColor Green
        $script:Pass++
    } else {
        Write-Host "[FAIL] $Name - should be ALLOWED but failed" -ForegroundColor Red
        $script:Fail++
    }
}

Write-Host "`n=== C-02 lateral movement: should be DENIED ==="
Test-Blocked "ping ASA inside interface" {
    Test-Connection 192.168.10.1 -Count 1 -Quiet -ErrorAction SilentlyContinue
}
Test-Blocked "SMB to inside host" {
    (Test-NetConnection 192.168.10.1 -Port 445 -WarningAction SilentlyContinue).TcpTestSucceeded
}
# <FILL: add a real inside host once one has a static address>

Write-Host "`n=== C-03 egress: should be DENIED (currently NOT enforced) ==="
Test-Blocked "arbitrary HTTPS" {
    try { (Invoke-WebRequest -Uri "https://<ARBITRARY_HOST>" -TimeoutSec 5 -UseBasicParsing) -ne $null }
    catch { $false }
}
Test-Blocked "public DNS" {
    (Test-NetConnection 8.8.8.8 -Port 53 -WarningAction SilentlyContinue).TcpTestSucceeded
}

Write-Host "`n=== permitted exceptions: should SUCCEED ==="
Test-Allowed "Xbox Live auth reachable" {
    (Test-NetConnection "<MS_AUTH_HOST>" -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded
}

Write-Host "`npassed: $Pass   failed: $Fail"
if ($Fail -gt 0) { exit 1 }
