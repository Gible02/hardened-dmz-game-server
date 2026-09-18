# 14 — Troubleshooting Log

> The most interesting page in the repo. Each failure below was isolated to a specific device
> before anything was changed — narrowing, not guessing.

---

## 1. Configuration silently reverting on every reload

**Symptom:** The 1921 came back to a bare configuration after each power cycle. Work done in one
session was gone by the next.

**Root cause:** The configuration register was set to `0x2142` — the value that instructs IOS to
skip `startup-config` at boot. It is the password-recovery setting. A device left in it looks
completely healthy and discards every change.

**How it was found:** `show version | include register` — after noticing the pattern was a reload
boundary rather than a specific command.

**Fix:**
```
config-register 0x2102
write memory
reload
show version | include register     → Configuration register is 0x2102
```

**Takeaway:** Verify persistence explicitly, by reload, not by assumption. A config that works
until the next reboot is not a working config — and on security devices, a control that silently
reverts is worse than one that was never configured, because you believe it is there.

---

## 2. Inbound NAT pointed at the wrong destination

**Symptom:** External UDP packets sent successfully from a cellular connection. The ASA's ACL hit
counters stayed at `hitcnt=0` on every line, including the explicit deny. Nothing arrived at the
server.

**Diagnosis path:**
1. Confirmed the ASA object was correct — `show run object id MC-SERVER` → `host 192.168.20.10`.
2. Confirmed the ACL was correct — `OUTSIDE-IN` line 1 permits UDP 19132 to that object.
3. A zero counter on the **explicit deny line** was the key clue. If packets were arriving and
   being rejected, line 5 would increment. Zero across every line means the packet never reached
   this interface in a form the ACL evaluates.
4. Moved upstream to the 1921 — `show run | section ip nat`.

**Root cause:** Two separate faults, found in sequence.

First, there was no inbound static NAT rule at all — only the outbound PAT overload. Optimum's
forward delivered UDP 19132 to the 1921's WAN interface and nothing told the router what to do
with it.

Second, once a static rule was added, it initially rewrote the destination to the ASA's own
outside interface address, `192.168.100.2`. That assumed the ASA would perform a second
translation onward to the server. **It does not** — this ASA routes and filters but performs no
NAT (`show nat` is empty). So the packet arrived addressed to the firewall itself, never matched
`OUTSIDE-IN` line 1 which expects a destination of `192.168.20.10`, and died at the implicit
deny without producing a useful log entry.

**Fix:**
```
no ip nat inside source static udp 192.168.100.2 19132 interface GigabitEthernet0/0 19132
ip nat inside source static udp 192.168.20.10 19132 interface GigabitEthernet0/0 19132
```

**Takeaway:** Destination NAT must name the actual end host unless something downstream is
translating again. Know which device in the chain owns translation before writing the rule.

And the diagnostic lesson, which is the more transferable one: a **zero hit counter on a
correct-looking ACL is evidence about where the packet is, not about whether the rule is right.**
If even the deny line is not incrementing, stop auditing the rule and start looking upstream.

---

## 3. No return path to the DMZ subnet

**Symptom:** With the NAT destination corrected, inbound traffic still failed.

**Root cause:** `show ip route 192.168.20.0` returned `% Network not in table`. The 1921's only
interfaces were the WAN (192.168.1.0/24) and the transit link (192.168.100.0/30). After
rewriting the destination to 192.168.20.10, the router had no idea how to reach it.

**Fix:**
```
conf t
 ip route 192.168.20.0 255.255.255.0 192.168.100.2
exit
show ip route 192.168.20.0
```

**Takeaway:** NAT rewrites an address; it does not create reachability. Translation and routing
are two independent requirements and both must be satisfied. The two faults presented with an
identical symptom, which is why fixing the first one alone appeared to change nothing.

---

## 4. ISP cable patched straight into the switch

**Symptom:** Everything worked — which was the problem.

**Root cause:** The ISP handoff went directly into the 2960X, bypassing the router and firewall
entirely. Internet access was fine, so nothing appeared wrong. Every control in the design was
inert: correctly configured, powered on, and enforcing nothing.

**How it was found:** Physically tracing each cable against the topology diagram.

**Takeaway:** A logical design means nothing until the physical path is traced. Working
connectivity proves packets move; it proves nothing about whether they are being inspected. This
is the failure mode that would never appear in a log, because there was no error to log.

---

## 5. ASA Gi0/1 would not establish link

**Symptom:** No link between the 1921's Gi0/1 and the ASA's Gi0/1 despite correct configuration
on both ends.

**Diagnosis — what was ruled out, in order:**
1. Configuration on both ends — verified, `no shutdown` present, addressing correct.
2. Cable — swapped for a known-good one, no change.
3. Far-end port — the 1921's Gi0/1 established link with a different device.
4. Same cable and config on the ASA's Gi0/3 — link came up immediately.

**Conclusion:** The ASA's Gi0/1 is physically faulty on this unit.

**Fix:** Outside interface relocated to Gi0/3; addressing and ACLs updated to match.

**Takeaway:** When configuration is provably correct on both ends and the cable is known-good,
suspect the hardware. Bisecting — swapping one variable at a time with a known-good reference —
turned an ambiguous failure into a definite one. Also: document the dead port, so future-you
does not re-debug it.

---

## 6. Residual config on a supposedly factory-default ASA

**Symptom:** An unexplained ACL entry referencing a WireGuard-style `192.168.10.10:51820` on
hardware that appeared factory-default.

**Why it mattered:** An inherited rule you did not write is an inherited rule you do not control.
Building on top of an unknown baseline means the final configuration cannot be fully reasoned
about — and on a firewall, an unexplained permit is a hole you do not know you have.

**Fix:** `write erase` + `reload`, then the full configuration rebuilt from a verified clean state.

**Takeaway:** Secondhand security hardware is an unknown baseline. Establish your own before
building on it. The extra hour is cheaper than doubting your own firewall later.

---

## 7. Server binary exiting instantly with no output

**Symptom:** `bedrock_server.exe` returned straight to the prompt. No startup logs, no log file,
no error text.

**Diagnosis:** Checked the exit code rather than guessing.
```powershell
$LASTEXITCODE        # → -1073741515
```
`-1073741515` is `0xC0000135`, `STATUS_DLL_NOT_FOUND`. Confirmed by checking for the runtime:
```powershell
Get-ChildItem "C:\Windows\System32\vcruntime140.dll","C:\Windows\System32\vcruntime140_1.dll"
```
Both absent.

**Root cause:** The Visual C++ Redistributable was not installed on the host.

**Fix:** Installed `vc_redist.x64.exe`, restarted, relaunched. Server started normally.

**Takeaway:** A silent exit still returns a code. Reading it turned a guess-and-check problem
into a two-minute fix. Windows exit codes in the `0xC0000xxx` range are NTSTATUS values and
decode to a specific fault.

---

## 8. Server installed inside a cloud-sync folder

**Symptom / constraint:** The server was initially extracted to a path under OneDrive.

**Why it mattered:** Bedrock worlds are a LevelDB database under continuous write. An active
sync client copying those files mid-write risks world corruption, sync conflicts, and file locks
that crash the server. Caught before the first real session rather than after.

**Fix:** Moved the installation to `C:\McServer\`.

**Takeaway:** Check where a service actually stores state before running it, not after the first
corruption.

---

## 9. Empty allowlist rejecting everyone

**Symptom / constraint:** With `allow-list=true` and an empty `allowlist.json`, the server
rejects every connection including the operator's.

**Fix:** `allowlist add <gamertag>` from the server console.

**Takeaway:** Minor, but worth recording — a control that is enabled but unpopulated fails
closed, which is the correct behaviour and exactly why it looked like a connectivity failure.

---

## What I'd do differently

- Trace the physical path first, before writing a single line of config. Failure #4 cost the most
  time for the least interesting reason.
- Check `show version | include register` as part of initial device intake, alongside the IOS
  version. Failure #1 silently invalidated an unknown amount of earlier work.
- Establish which device owns NAT before writing any translation rule. Failures #2 and #3 both
  trace back to an unstated assumption about that split.
- Read exit codes and counters before changing configuration. Both times the diagnostic data was
  already on screen.

## What's next

- Implement default-deny egress (C-03 / R-05) — the highest-value remaining work.
- Test the containment rule (T-07) and capture the hit counter. The control is configured but
  unproven.
- Apply and verify switch hardening (C-07).
- Build the pull-based backup routine and run one real restore (C-11).
- Build config backup and drift detection (C-12).
