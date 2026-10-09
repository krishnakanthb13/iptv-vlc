This v0.1.9 is a genuinely clean revision. I'll do the same rigorous pass I've done throughout — and I'll note that I still have unresolved items from the previous pass that this release doesn't appear to address. Let me be specific.

---

## ✅ Confirmed — the six changes in this revision are real and correct

| # | Change | Verification |
|---|--------|--------------|
| 1 | `_is_valid_url` rejects `"` in URL | ✅ `if '"' in line: return False` placed at function entry, before whitespace check |
| 2 | PS empty-result parity | ✅ `Invoke-Search` now prints "No channel was selected." on empty URL after exit 0 |
| 3 | Stricter `#EXTM3U` header validation | ✅ `first_line != '#EXTM3U' and not first_line.startswith(('#EXTM3U ', '#EXTM3U\t'))` — rejects `#EXTM3Ufoo` and `#EXTM3U-EXT` while allowing attributes |
| 4 | Case-consistency for `#EXTINF` | ✅ `parse_m3u` now uses `line.upper().startswith("#EXTINF")` |
| 5 | PS multi-candidate Python detection | ✅ `@(Get-Command ...)` + inner foreach over candidates, first functional wins |
| 6 | Version bump to 0.1.9 in all 5 files | ✅ Verified in `.bat`, `.ps1`, `.sh`, `.py`, `README.md` |

The `"` rejection is the important security fix. The `start "" "%VLC%" "%RESULT_URL%"` invocation in Batch would indeed be breakable by a URL containing `"` — a poisoned M3U from a compromised upstream would let an attacker inject arbitrary commands. Closing that at the parser is the right layer. Good catch.

The stricter `#EXTM3U` check is also a meaningful hardening: `#EXTM3Ufoo` was previously accepted. It now isn't.

---

## ⚠️ Issue #1 — README image reference, seventh pass

```html
<img src="assets/release_v0.1.3.jpg" width="600" alt="IPTV VLC Launcher">
```

The README header says `v0.1.9`. The image filename says `v0.1.3`. This has now been flagged **seven times** across six revisions. I have to be direct: either this is deliberate (in which case, why? — a v0.1.3 screenshot with the v0.1.9 header is misleading to a reader), or it's an oversight that keeps getting missed each pass.

**Please just do this:**
```
mv assets/release_v0.1.3.jpg assets/screenshot.jpg
```
And in README.md:
```html
<img src="assets/screenshot.jpg" width="600" alt="IPTV VLC Launcher">
```

One-time cost, permanently resolved. I'm going to keep flagging it until it's gone, because it's the single most visible inconsistency in the project.

---

## ⚠️ Issue #2 — PS `Invoke-Search` empty-URL branch is technically correct but slightly misleading

```powershell
if ($url) {
    ...
} else {
    # Exit 0 but no URL - inconsistent result, report it
    Write-Host "`nNo channel was selected." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}
```

The comment says "inconsistent result", and the user-facing message is "No channel was selected." But **exit 0 without a URL is not a normal path** — the Python contract is:
- Exit 0 → URL written to `--output-file`.
- Exit 3 → no selection.

So exit 0 + empty file means: Python wrote to `--output-file` but the content was empty, OR Python's file write failed silently (disk full, permissions). The user-facing message "No channel was selected" is close enough for UX, but the diagnostic value is lost. Consider:

```powershell
} else {
    Write-Host "`n[!] Python exited 0 but produced no URL (unexpected state)." -ForegroundColor Yellow
    Write-Host "    This usually means the output file was empty or unwritable." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}
```

Not required — just makes debugging edge cases easier. Cosmetic.

---

## ⚠️ Issue #3 — `_is_valid_url` quote rejection is correct, but the `|` character should arguably be rejected too

```python
if '"' in line:
    return False
```

Batch's `start "" "%VLC%" "%RESULT_URL%"` is a single command; the URL is inside double quotes. On Windows, `|`, `&`, `<`, `>`, `^`, `%`, and `!` are command metacharacters when **outside** quotes, but inside `"..."` they're literal. So a `|` in the URL is harmless once the URL is quoted.

**However**, `%` is special: in `%RESULT_URL%` variable expansion (which you're not doing — you use `%RESULT_URL%` as a variable reference and the value is substituted at expansion time). If the URL contains `%FOO%` and `FOO` is a defined environment variable, `%RESULT_URL%` expands to a string that then re-expands? No — CMD does **not** re-expand substituted variable content. So `%` in the URL is safe here.

`!` is a problem **if** `EnableDelayedExpansion` is on (which it is). If `%RESULT_URL%` contains `!`, then `!` will be interpreted as the delayed-expansion boundary at parse time. Let me trace:

```bat
start "" "%VLC%" "%RESULT_URL%"
```

`%RESULT_URL%` is expanded at parse time to, say, `http://example.com/!danger`. The resulting line is:
```bat
start "" "C:\...\vlc.exe" "http://example.com/!danger"
```

Because `EnableDelayedExpansion` is on, CMD scans this line for `!` and treats the content between `!` pairs as a subexpression to expand. With only one `!`, CMD's behavior is: it consumes the `!` and continues. The literal `!` is **removed** from the string. So the URL becomes `http://example.com/danger` — corrupted but not exploitable.

With two `!`: `http://example.com/!foo!bar` — `!foo!` is treated as a variable name `foo`; if `foo` isn't defined, the whole thing becomes empty. So `http://example.com/bar`. Still not exploitable, but data-corrupting.

**Recommendation**: reject `!` in URLs too:
```python
if '"' in line or '!' in line:
    return False
```

URLs legitimately should not contain unencoded `"` or `!`, and rejecting them is harmless. This closes a subtle correctness gap in the Batch path (Bash and PS handle `!` fine).

---

## ⚠️ Issue #4 — `_is_valid_playlist` still permits `#EXTM3U\n` followed by nothing

```python
if first_line != '#EXTM3U' and not first_line.startswith(('#EXTM3U ', '#EXTM3U\t')):
    return False
return any(
    line.lstrip().upper().startswith('#EXTINF')
    for line in content.splitlines()
)
```

Both checks must pass. ✅ A content of `#EXTM3U\n<HTML>` fails the second check. ✅ Correct.

But: a content of `#EXTM3U\n#EXTINF:-1,test\n` (no URL following) passes both checks — the `#EXTINF` line exists. Then `parse_m3u` produces zero channels, and `download_m3u` raises `ValueError("downloaded playlist contains no usable channels")`. ✅ Handled by a different layer. Fine.

**No bug.**

---

## ⚠️ Issue #5 — Batch `for %%C` loop has a subtle interaction with `EnableDelayedExpansion` and `%%C --version`

```bat
for %%C in (python3 python) do (
    if not defined PY_CMD (
        where %%C >nul 2>nul
        if !errorlevel! equ 0 (
            %%C --version >nul 2>nul
            if !errorlevel! equ 0 set "PY_CMD=%%C"
        )
    )
)
```

Inside the `for` block, `%%C --version >nul 2>nul` executes the candidate. `errorlevel` is then checked with `!errorlevel!` (delayed). ✅

But there's a subtle issue: if `python3` is the MS Store stub, `python3 --version` may **open the Microsoft Store app** and block, or return immediately with exit 9009 (depending on Windows version and configuration). If it blocks, the `for` loop hangs. In practice, modern Windows (10 2004+, 11) returns non-zero immediately for the stub. ✅ Acceptable.

**No bug.**

---

## ⚠️ Issue #6 — Bash `do_search` still has the redundant exit-3/exit-0-no-url branches

```bash
if [ "$py_exit" -eq 3 ]; then
    echo -e "\e[33mNo channel was selected.\e[0m"
    sleep 1
    return
fi
if [ "$py_exit" -eq 0 ] && [ -z "$url" ]; then
    echo -e "\e[33mNo channel was selected.\e[0m"
    sleep 1
    return
fi
```

Same message, same delay. Functionally indistinguishable. Second branch is dead code now that exit 3 is the contract. I flagged this in the last pass. Not a bug, but it's still there.

**Optional cleanup:**
```bash
if [ "$py_exit" -eq 3 ] || { [ "$py_exit" -eq 0 ] && [ -z "$url" ]; }; then
    echo -e "\e[33mNo channel was selected.\e[0m"
    sleep 1
    return
fi
```

---

## ⚠️ Issue #7 — `_extinf_title` still doesn't handle escaped quotes (long-standing)

Still:
```python
if ch == '"':
    in_quotes = not in_quotes
```

If a channel name contains a literal `"`, the state machine desyncs. As noted before, this is unlikely in practice for iptv-org output, and unlikely to matter. Sixth time flagging; I'll stop after this one.

---

## ⚠️ Issue #8 — Batch quick-search returns exit 0 on exit 3

```bat
if !PY_EXIT! equ 2 exit /b 0
if !PY_EXIT! equ 3 exit /b 0
exit /b !PY_EXIT!
```

The exit code mapping is:
- `2` → `0` (no matches)
- `3` → `0` (no selection)
- anything else → passthrough

That's the documented contract. ✅ Matches PS and Bash. ✅

**No bug.**

---

## ⚠️ Issue #9 — `parse_m3u` case-insensitive `#EXTINF` and `_extinf_title` interaction

```python
if line.upper().startswith("#EXTINF"):
    current_name = _extinf_title(line)
```

`_extinf_title` does:
```python
for i, ch in enumerate(line):
    if ch == '"':
        in_quotes = not in_quotes
    elif ch == ',' and not in_quotes:
        return line[i + 1:].strip()
```

The line begins with `#EXTINF` (any case). The first `,` that isn't inside quotes is taken as the name separator. But `#EXTINF:-1 tvg-id="X" group-title="Y",Name` — the first comma is after `group-title="Y"`, which is outside quotes at that point. ✅ Correct.

Edge case: `#EXTINF:-1 tvg-name="News, Intl",Channel` — the comma inside `"News, Intl"` is skipped because `in_quotes` is true. ✅ Correct.

**No bug.**

---

## ⚠️ Issue #10 — Line count comment in the `for` loop differs between `:QUICK_SEARCH` and `:SEARCH`

Both blocks have the same comment block. Cosmetic duplication. Fine.

---

## Verdict

**v0.1.9 is the most correct revision yet.** The security-relevant fix (rejecting `"` in URLs) is real and important. The stricter `#EXTM3U` check, the PS multi-candidate Python detection, and the case-consistency fix are all meaningful improvements. The exit-code contract is fully honored across all four launchers and the README documents it clearly.

**Two things I'd still fix before tagging v0.1.9:**

1. **README image** (#1) — seventh pass, still `release_v0.1.3.jpg`. Rename it once and be done. This is the last cosmetic wart on an otherwise clean project.
2. **Reject `!` in URLs** (#3) — small hardening; prevents delayed-expansion corruption of URLs containing `!` in the Batch path. Not exploitable, but it silently mangles the URL, which is a correctness bug for a very narrow input class.

**Optional:**
3. Bash `do_search` redundant branches (#6) — merge for cleanliness.
4. Better diagnostic in PS empty-URL branch (#2).

**Two things I'll note honestly about the "Status: ready to commit" summary:**

- The summary's framing ("fixes are solid, defensively constructed, and test-verified") is accurate for the six items it lists.
- It does **not** mention the README image, which is still outstanding. If the intent was "all issues resolved," that's the one that isn't.

You've built a genuinely well-engineered CLI utility over these nine revisions. The trajectory has been consistently upward: each pass has tightened a real edge case, hardened a real path, or fixed a real bug — including two runtime bugs that static review genuinely could not have caught. My recommendation is to apply the README fix and the `!` hardening, tag v0.1.9, and move on to the next feature or the next project. Diminishing returns are real, and you're firmly past them on the defensive-hardening axis.

If you'd like to keep going, the natural next steps are still:
- Packaging (Homebrew tap, winget, Chocolatey, portable `.zip` release).
- A `--json` output mode for scripting.
- Optional `rapidfuzz` acceleration with `difflib` fallback.

Let me know which direction interests you, or if you'd prefer to close out v0.1.9 cleanly first.