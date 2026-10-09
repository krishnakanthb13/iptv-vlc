Thanks — and I'll return the honesty favor one more time: **v0.1.6 is genuinely excellent, but "pristine" is still an overstatement.** The three major issues I flagged (double-parse, whitespace URLs, cache-poison `#EXTINF` spoofing) are indeed resolved, and the `(lines, channels)` tuple refactor is a clean, correct fix. But this revision introduced at least two new behaviors worth examining, and one pre-existing concern is now sharper because of the refactor. None of these are release-blockers; they're the kind of thing that separates "very good" from "bulletproof."

---

## ✅ Confirmed — the three headline fixes hold up

| Fix | Verified |
|-----|----------|
| Double/triple parse eliminated | `download_m3u` returns `(lines, channels)`; `main` uses `channels` directly; no second `parse_m3u` in the common path. ✅ |
| Whitespace/control-char URL rejection | `if any(ord(c) < 32 or c.isspace() for c in line): return False` — correct, and correctly placed **before** `urlparse`. ✅ |
| `_is_valid_playlist` per-line `#EXTINF` check | `any(line.lstrip().upper().startswith('#EXTINF') for line in content.splitlines())` — much harder to spoof than the previous whole-content substring check. ✅ |
| Batch interactive search now has 4-way branch | `if defined RESULT_URL … else if !PY_EXIT! equ 2 … else if !PY_EXIT! neq 0 … else …` — mirrors PS behavior. ✅ |
| `--version` in argparse | Present. ✅ |
| README documents `--force-refresh` CLI-only limitation | Present, and the note is now placed **before** the example. ✅ |

The `(lines, channels)` return is the right shape, and `main()` reads much better now. Good call.

---

## 🐛 New Issue #1 — `download_m3u` docstring promises behavior the code doesn't quite deliver

```python
def download_m3u(force_refresh=False):
    """Downloads the master M3U list, caches it, and returns (lines, channels).

    Validates downloaded content before replacing the cache, falls back to the
    previous cache when the download fails, and exits with status 1 on a
    fatal error. The playlist is parsed exactly once per code path.
    """
```

The "parsed exactly once per code path" claim is **almost** true, but not quite. In the fallback paths:

```python
if force_refresh and old_lines:
    old_channels = parse_m3u(old_lines)     # parse #1
    if old_channels:
        ...
        return old_lines, old_channels
if cache_age is not None:
    lines = _read_cache()                    # <-- re-reads cache from disk
    if lines:
        channels = parse_m3u(lines)          # parse #2
        if channels:
            ...
            return lines, channels
```

Two things:

1. **`_read_cache()` is called again** on the non-forced fallback path, even though `cache_age` was computed from the same file. Minor I/O, but redundant — you already have `cache_age is not None` implying a cache exists.

2. More importantly: on the **forced-refresh failure** path, `old_lines` was read at the top *before* the try block, and `parse_m3u(old_lines)` runs **only inside the `except`**. If the download succeeds, `old_lines` is parsed **zero times** (correct — it's not used). If the download fails, it's parsed **once** (correct). So the "exactly once per code path" claim is true for the *success* path, and true for the *fallback* path. It's a slightly aspirational claim, but not wrong.

**However** there's an actual subtle issue: on the **fallback path after a failed non-forced refresh**, you call `_read_cache()` a *second* time — this means reading ~30k lines from disk again. Cheap but pointless. Consider reusing `cache_age`-derived content:

```python
# Cache exists but is stale; try reading it once for fallback
cached_lines = _read_cache()   # read once at the top if cache_age is not None
```

Then both the "valid cache" and "fallback" paths share one read. Not urgent, but it removes the redundant syscall and makes the docstring's claim literally true.

---

## 🐛 New Issue #2 — Batch `:SEARCH` 4-way branch has a subtle ordering bug

```bat
if defined RESULT_URL (
    echo.
    echo Launching VLC with selected stream...
    start "" "%VLC%" "%RESULT_URL%"
) else if !PY_EXIT! equ 2 (
    echo.
    echo No channels matched your search.
    timeout /t 2 >nul
) else if !PY_EXIT! neq 0 (
    echo.
    echo X Search engine failed (exit !PY_EXIT!).
    timeout /t 3 >nul
) else (
    echo.
    echo No channel was selected.
    timeout /t 2 >nul
)
```

Consider these scenarios:

- **User picked a channel → RESULT_URL defined → launches VLC.** ✅
- **User pressed 0 / Ctrl+C → RESULT_URL empty, PY_EXIT=0 → "No channel was selected."** ✅
- **No matches → PY_EXIT=2 → "No channels matched."** ✅
- **Python crashed → PY_EXIT=1 → "Search engine failed (exit 1)."** ✅

Wait — the ordering is `defined RESULT_URL` first, then `PY_EXIT equ 2`, then `PY_EXIT neq 0`. That covers everything. Fine. **No bug.** I was wrong to flag this as a potential issue. My mistake.

Actually, let me be more careful. One edge case: what if Python **writes the URL file but then exits 2** (e.g., a bug in the write path that shouldn't happen)? Then `RESULT_URL` is defined and VLC launches, ignoring the exit code. That's a hypothetical, and arguably the right behavior (URL was produced). Fine.

**Retracting Issue #2.** Batch is correct.

---

## ⚠️ Issue #3 — `parse_m3u` is now called inside `download_m3u`, which makes it a hard dependency of cache validity

```python
if lines:
    channels = parse_m3u(lines)
    if channels:
        ...
        return lines, channels
```

This is correct behavior. But it means: **if `parse_m3u` has any bug or accepts any malformed input as a "channel", the cache-validity check inherits that bug.** That's fine — it's the same code that will be used for the actual search, so at least it's consistent.

The thing to be careful of going forward: **`parse_m3u` is now load-bearing for cache freshness**. Any future change to it silently changes when caches are considered "valid". Worth a comment in `_is_valid_playlist` or `download_m3u` noting this coupling:

```python
# NOTE: parse_m3u is the authoritative definition of a "usable channel".
# Any change to it also changes cache-validity semantics.
```

Not urgent. Just worth recording so a future maintainer doesn't accidentally break cache validity by "improving" `parse_m3u`.

---

## ⚠️ Issue #4 — README image still points to `release_v0.1.3.jpg`

```html
<img src="assets/release_v0.1.3.jpg" width="600" alt="IPTV VLC Launcher">
```

Header says `v0.1.6`. I've flagged this cosmetic mismatch **four times** now. It's clearly intentional at this point, or it's being missed each pass. Either way:

- If the file on disk is `release_v0.1.3.jpg`, rename it to `screenshot.jpg` and use that name — version-agnostic, never needs touching again.
- If the file is missing, the README shows a broken image on GitHub.

This is the single easiest fix in the whole project. Just do it.

---

## ⚠️ Issue #5 — `_is_valid_url` whitespace check is correct but subtly over-strict

```python
if any(ord(c) < 32 or c.isspace() for c in line):
    return False
```

`c.isspace()` covers `' '`, `'\t'`, `'\n'`, `'\r'`, `'\v'`, `'\f'`, and — importantly — **Unicode whitespace** like `'\u00A0'` (non-breaking space), `'\u2003'` (em space), and `'\u3000'` (ideographic space). The `ord(c) < 32` clause is therefore redundant with `c.isspace()` for ASCII control chars, but harmless.

**The concern**: some IPTV streams legitimately contain Unicode in the URL — e.g., IDN hostnames encoded as raw Unicode instead of punycode (`http://例え.jp/stream`), or percent-encoded paths where the percent-encoded form contains no literal spaces. A literal Unicode space inside a URL is genuinely malformed, so rejecting it is correct. **This is fine.** But it's worth knowing that the check will also reject any URL with an ideographic space (`\u3000`), which is almost never valid anyway. No fix needed — just a note.

Actually, one place this could bite: some M3U files use `#EXTVLCOPT:http-user-agent=...` lines. Those start with `#` and are skipped by `parse_m3u`, so they never reach `_is_valid_url`. Fine.

**No issue.** Retracting.

---

## ⚠️ Issue #6 — `download_m3u` returns a tuple, but `main` still prints the channel count outside

```python
lines, channels = download_m3u(force_refresh=args.force_refresh)
print(f"[i] Loaded {len(channels)} channels")
```

Note `lines` is now **unused** in `main`:

```python
lines, channels = download_m3u(...)
print(f"[i] Loaded {len(channels)} channels")
matches = fuzzy_search(args.query, channels, ...)
```

`lines` is captured but never read. Linters (pyflakes, ruff F841) will flag this. You could either:

1. Return only `channels` from `download_m3u` — cleanest.
2. Return `(lines, channels)` and use `_lines` for the unused one — conventional but a bit ugly.
3. Keep it as is and accept the lint warning.

Since `lines` is genuinely unused by callers, **Option 1** is the cleanest fix:

```python
def download_m3u(force_refresh=False) -> list:
    """... returns the parsed channel list."""
    ...
    return channels
```

And `main` becomes:
```python
channels = download_m3u(force_refresh=args.force_refresh)
print(f"[i] Loaded {len(channels)} channels")
```

If you ever want `lines` for something else (e.g., a `--dump-m3u` flag), you can reintroduce the tuple then. Right now it's dead data.

---

## ⚠️ Issue #7 — Bash `do_search` and Batch `:SEARCH` don't distinguish "user cancelled" from "no results"

Python exits **0** when the user cancels (`pick == '0'` → `return` from `main()` → process exits 0). So the shells see:

| Outcome | Exit code |
|---------|-----------|
| User picked a channel | 0 (and result file written) |
| User pressed 0 / Ctrl+C | 0 (result file empty) |
| No matches found | 2 |
| Error | 1 |

In Batch `:SEARCH`:
```bat
) else (
    echo.
    echo No channel was selected.
    timeout /t 2 >nul
)
```

This catches both "user cancelled" (exit 0, no URL) and any other exit-0-no-URL case. Correct.

In Bash `do_search`:
```bash
if [ -n "$url" ]; then
    echo -e "\e[32mLaunching VLC...\e[0m"
    ...
fi
```

If the user cancels, `$url` is empty, `py_exit` is 0, and neither the `-eq 1` nor the `-eq 2` branch fires — so **nothing is printed** and control returns to the menu. That's *fine*, but it's slightly inconsistent with PowerShell (`Invoke-Search` also does nothing in that case — OK) and Batch (prints "No channel was selected."). Minor cosmetic parity gap: Batch tells the user nothing happened; Bash silently returns.

Not a bug. Just an inconsistency worth noting if you're aiming for exact user-facing parity. A one-line addition:

```bash
if [ "$py_exit" -eq 0 ] && [ -z "$url" ]; then
    echo -e "\e[33mNo channel was selected.\e[0m"
    sleep 1
    return
fi
```

---

## ⚠️ Issue #8 — `_is_valid_playlist` lstrip signature is fragile

```python
head = content.lstrip('﻿\r\n \t')
```

The first character after the opening quote is a **BOM** (`\uFEFF`). It's invisible in most editors. This works, but is fragile:

- Some editors/tools may strip the BOM during copy-paste, silently changing what characters are stripped.
- If someone later edits the string in a plain ASCII editor, the BOM may be lost.

**Safer:**
```python
BOM = '\ufeff'
head = content.lstrip(BOM + '\r\n \t')
```

Or just:
```python
head = content.lstrip('\ufeff\r\n \t')
```

Same semantics, but immune to invisible-character loss. Cosmetic, but worth doing.

---

## ⚠️ Issue #9 — `urlparse` accepts URLs with empty paths that might be proxies' error responses

Not really an issue — a URL like `http://example.com` (no path) is valid. iptv-org streams usually have paths. Leaving as-is is correct.

---

## ⚠️ Issue #10 — README says "whitespace validation" but doesn't mention the new behavior's limits

> **Robust URL Validation**: Scheme, hostname, and whitespace validation keeps `http`/`https` plus VLC-playable schemes (`rtsp`, `rtmp`, `udp`, `rtp`, `mms`) and rejects malformed entries.

Accurate. One small note: the whitespace check now rejects *any* whitespace anywhere in the URL line, including well-intentioned-but-malformed cases where a user manually pasted a URL with a trailing space. That's the right behavior, but you might add "URLs must be whitespace-free (as required by RFC 3986)" if you want to preempt confusion. Optional.

---

## Verdict (honest, final)

**v0.1.6 is a genuine improvement over v0.1.5 and is ready to ship.** The tuple refactor is elegant, the whitespace check is correctly ordered, and the per-line `#EXTINF` check is a real hardening step. You've addressed every issue I raised in the last pass.

**Before you tag it, the two fixes I'd actually do:**

1. **Drop `lines` from the return tuple** (#6) — it's dead data and will trip linters. Easy, safe, cleans the API.
2. **Fix the README image path** (#4) — four passes of flagging this; just rename the file and use `screenshot.jpg`.

**Optional nice-to-haves, not required:**
3. Replace the literal BOM in `lstrip` with `'\ufeff'` (#8).
4. Add a "No channel was selected" message in Bash `do_search` for exact parity (#7).
5. Add the coupling comment to `download_m3u` (#3).

None of these are release-blockers. But I want to be clear: **"pristine" is not the right word** for code that still has a dead variable and a four-times-flagged broken README image reference. "Very good, with a couple of loose ends" is the honest verdict. If you ship v0.1.6 as-is, it works correctly; if you ship it with those two small fixes, it's genuinely tight.

You've done excellent work here — the tool is now more defensive, more correct, and better documented than most CLI utilities of comparable scope. Ship with the two small fixes and it'll be a clean v0.1.6; or hold for v0.1.7 if you want to knock out the optional items too. Either way, you're past the point of diminishing returns on this revision.