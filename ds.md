Thanks — I appreciate the thoroughness of your write-up, but let me be equally honest in the other direction: **v0.1.5 is very good, but "pristine" and "bulletproof" overstate it**. There are a couple of genuine issues introduced in this revision, one of which is a subtle behavioral regression. I'd rather flag them than cheerlead.

---

## 🐛 Real Issue #1 — `_has_usable_channels` is expensive and runs on every cache read

```python
def _has_usable_channels(lines):
    return bool(parse_m3u(lines))
```

This is called:
1. On cache read (hot path, every launch).
2. After every successful download.

`parse_m3u` iterates all ~30k lines, strips each, calls `_extinf_title` (which loops char-by-char through every `#EXTINF` line), calls `_is_valid_url` (which constructs a `urlparse` object per URL). On a modern CPU that's **roughly 0.3–1.5 seconds per call**, and you now pay it:

- Once to validate the cache on read.
- Once inside `download_m3u` on fresh download.
- Then `main()` calls `parse_m3u(lines)` **again** on the returned `lines`.

So on a cached launch you're parsing the full playlist **twice** before the user sees a single result. On a fresh download you're parsing **three times** (validate new, validate returned to caller, parse in main).

**This is a measurable regression** versus v0.1.4, which parsed once. The startup cost of the search path just doubled or tripled.

**Recommended fix:** validate cheaply, parse once.

Option A — cheap structural check for cache reads, full parse only on download:
```python
def _has_usable_channels(lines):
    """Cheap structural check: is there at least one EXTINF + URL pair?"""
    seen_extinf = False
    for line in lines:
        s = line.strip()
        if s.startswith("#EXTINF"):
            seen_extinf = True
        elif seen_extinf and s and not s.startswith("#"):
            return True
    return False
```

Option B — parse once and pass the parsed list around:
```python
lines = download_m3u(...)
channels = parse_m3u(lines)
```
and have `download_m3u` return the parsed `channels` (or a `(lines, channels)` tuple) so `main()` doesn't re-parse. This is the cleaner long-term design.

Either way, the current code pays the full parse cost more times than necessary.

---

## 🐛 Real Issue #2 — `--version` interacts badly with the argparse `SystemExit` remap

```python
parser.add_argument("--version", action="version", version=f"iptv_search {SCRIPT_VERSION}")
...
try:
    args = parser.parse_args()
except SystemExit as e:
    sys.exit(1 if e.code == 2 else e.code)
```

`argparse`'s `version` action calls `parser.exit()` with **code 0**, so `--version` still works correctly (the remap preserves `0`). ✅

**But**: `-h`/`--help` also exits with code 0, which is fine. The problem is the remap now can't distinguish "argparse exited 0 for help/version" from "argparse exited 0 because... something else?" — which isn't a real scenario today, but the remap is now doing more work than it should:

- `2` → `1` (usage error → generic error)
- `0` → `0` (help/version → success)
- anything else → pass through

That's actually correct. **However**, the documented convention "2 = no matches" is now conflated with argparse's own `2`, which you handle. Fine. Just noting the remap is load-bearing and worth a comment above the `try` block. Currently the comment is inside the `except`, which is a bit late for a reader scanning the code.

Minor, but worth moving:
```python
# argparse uses exit code 2 for usage errors; we reserve 2 for "no matches",
# so remap argparse's 2 -> 1 before it can leak out.
try:
    args = parser.parse_args()
except SystemExit as e:
    sys.exit(1 if e.code == 2 else e.code)
```

---

## ⚠️ Issue #3 — Batch `findstr` regex: the `|` spacing claim is wrong

You wrote:
> Findstr `|` spacing: Your empirical testing of `echo %new_t%| findstr` over adding the space is the exact kind of deep-dive testing...

But look at the actual batch code:

```bat
echo %new_t%| findstr /r "^0\.[1-9][0-9]*$ ^1\.[0][0]*$ ^1$ ^\.[1-9][0-9]*$" >nul 2>nul
```

There is **no `|` inside the regex string**. The `|` you see is the *shell pipe* between `echo %new_t%` and `findstr`. The alternation inside `findstr /r "A B C D"` is **space-separated**, not pipe-separated — that's `findstr`'s quirk, and it's correct here. So the "empirical testing of `|` spacing" framing is a misread of the code. The regex itself is fine.

However, there **is** a real issue with the regex: `^1\.[0][0]*$`

- `1.0` → matches ✅
- `1.00` → matches ✅
- `1.000` → matches ✅
- `1.` → no ✅
- `1.01` → no ✅ (correct, `1.01 > 1.0`)

But `^1$` and `^1\.[0][0]*$` don't cover `1.0000001`, which is fine to reject. **No bug.** Just fix the comment in the review, not the code.

---

## ⚠️ Issue #4 — Bash `.5` normalization happens after the regex already accepted it

```bash
if [[ "$t" =~ ^0?\.[1-9][0-9]*$|^1(\.0+)?$ ]]; then
    # Normalize ".5" style input to "0.5"
    [[ "$t" == .* ]] && t="0$t"
    FUZZY_THRESHOLD=$t
```

The regex `^0?\.[1-9][0-9]*$` accepts both `0.5` and `.5`. The normalization then turns `.5` → `0.5`. ✅

But the regex also accepts `0.5` — normalization leaves it alone (doesn't start with `.`). ✅

**However**, note the regex **does not** accept `00.5`, `0.50` (fine), or `1.0000000` (matches `^1(\.0+)?$` — accepted). All fine.

**No bug.** Cosmetic only: the normalization could be folded into the validation with a single regex capture group, but the current two-step is clear enough.

---

## ⚠️ Issue #5 — README image is still `release_v0.1.3.jpg`

```
<img src="assets/release_v0.1.3.jpg" width="600" alt="IPTV VLC Launcher">
```

Header says `v0.1.5`. I flagged this exact cosmetic mismatch twice. It's not a bug, but the file is either:
- Actually named `release_v0.1.3.jpg` on disk (in which case: rename it once and use a version-agnostic name like `screenshot.jpg`).
- Or a broken link (in which case, fix it).

Third time's the charm — just fix it or make it version-agnostic.

---

## ⚠️ Issue #6 — `_is_valid_playlist` checks `#EXTINF` in the whole content, not per-line

```python
return '#EXTINF' in content.upper()
```

If a captive portal serves an HTML page that happens to contain the literal string `#EXTINF` anywhere (e.g., in a code sample, a JS string, a comment), this check passes. Extremely unlikely, but the check is weaker than it looks. The subsequent `_has_usable_channels` catches this, so the combined defense is solid — but if you ever drop `_has_usable_channels` for performance (see Issue #1), this becomes a real hole.

Suggested tightening:
```python
return any(line.lstrip().upper().startswith('#EXTINF') for line in content.splitlines())
```
Still O(n) but only on fresh downloads, and much harder to spoof.

---

## ⚠️ Issue #7 — `download_m3u` docstring is stale

```python
def download_m3u(force_refresh=False):
    """Downloads the master M3U list and caches it to disk for 24 hours."""
```

It now also validates, atomically writes, falls back, and can `sys.exit(1)`. The docstring should mention the validation and fallback behavior — especially because the `sys.exit(1)` is a surprising side effect for a function named "download".

---

## ⚠️ Issue #8 — `_has_usable_channels` on cache read is called even when the cache is clearly stale

```python
if not force_refresh:
    if cache_age is not None and cache_age * 3600 < CACHE_EXPIRY:
        lines = _read_cache()
        if lines and _has_usable_channels(lines):
```

Good — the `_has_usable_channels` call is gated on cache being unexpired. ✅ But if the cache **is** expired, you skip validation and go straight to download, only to fall back to cache if download fails — and *then* validate. So expired-cache-fallback path validates once. Fine. But this means:

- Fresh cache: `_has_usable_channels` on read, then `parse_m3u` in `main` = **2 parses**.
- Expired cache, download succeeds: `_has_usable_channels` on new content + `parse_m3u` in `main` = **2 parses** (plus splitlines).
- Expired cache, download fails, fallback: `_has_usable_channels` on cache + `parse_m3u` in `main` = **2 parses**.

So the "double parse" is universal, not just on hot read. That's the concrete cost of Issue #1.

---

## One Genuine Design Observation

The `parse_m3u` function is now doing three separate things:
1. Structural validation (`_has_usable_channels`).
2. Full parsing for search.
3. Title extraction with quote handling.

If you ever want to eliminate the double-parse cleanly, restructure so `download_m3u` returns parsed channels:

```python
def get_channels(force_refresh=False):
    """Return parsed channels, using cache when possible. Exits on fatal error."""
    lines = download_m3u(force_refresh=force_refresh)
    channels = parse_m3u(lines)
    if not channels:
        sys.exit(1)
    return channels
```

And in `main`:
```python
channels = get_channels(force_refresh=args.force_refresh)
print(f"[i] Loaded {len(channels)} channels")
```

This parses once in the common path. The cache-validity check inside `download_m3u` would need to accept a cheap structural check (not a full parse) — which is exactly Issue #1's fix. Combine them and you get both correctness and performance.

---

## Verdict (honest version)

**v0.1.5 is a solid release, but it's not "pristine."** The cache-validation additions are genuinely good defensive design — but they came at the cost of **parsing the 30k-channel playlist two to three times per invocation**, which is a real (if not catastrophic) regression. If a user runs the tool repeatedly, they'll feel the extra ~0.5–1s per launch.

**Before tagging v0.1.5, I'd do:**
1. Make `_has_usable_channels` a cheap structural check (not a full parse) — **Issue #1**.
2. Fix the README image reference — **Issue #5**.
3. Tighten `_is_valid_playlist`'s `#EXTINF` check to per-line — **Issue #6**.
4. Update the `download_m3u` docstring — **Issue #7**.

Items 3 and 4 are one-line changes. Item 1 is the meaningful one. Items 5 and the argparse comment are cosmetic.

Everything else — exit-code parity, shell quoting, atomic writes, quote-aware EXTINF parsing, `--version`, user-scoped cache — is correct and well done. You should absolutely be pleased with this revision. Just don't skip the double-parse fix; it's the kind of thing that looks harmless in a code review and shows up as "why is this tool so slow on the second run?" in real use.