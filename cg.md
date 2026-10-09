# IPTV VLC Launcher v0.1.4 — Revision 8 Audit

The latest revision has meaningful improvements. Python compilation and Bash syntax checks pass, and the earlier malformed-hostname issue appears fixed. However, I would not yet call this release-ready: I found a remaining cache-validation defect and a sensitivity-validation mismatch that contradict the documented `0.1–1.0` range.&#x20;



## Findings

1\. Playlist validation can still poison the cache

High priority

`_is_valid_playlist()` checks for an `#EXTM3U` first line and the presence of `#EXTINF` somewhere in the content. It does not verify that the download contains even one parseable channel before replacing the existing cache.

I tested three invalid playlist bodies: a bare `#EXTINF` line, an invalid stream URL, and a comment containing `#EXTINF`. All three passed the current validation, yet parsed into zero channels.&#x20;



Fix: Parse and validate the downloaded playlist before `os.replace()`. Require at least one usable channel entry, and keep the existing cache if validation fails. Consider validating cached content too before returning it.

2\. Sensitivity validation accepts values below 0.1

Medium priority

The Bash expression accepts decimal values such as `0.01` and `0.0`; the Batch `findstr` patterns also permit values below the documented minimum. The Python CLI subsequently rejects these values, so the shell launchers can accept a setting that the search engine will not accept. The README documents the supported range as `0.1–1.0`.&#x20;

README.md



Fix: Apply a numeric range check after validating the input's format in both shells. Keep `.5` support if desired, but normalize it to `0.5` and reject values below `0.1` or above `1.0`.

3\. Bash invokes Python without quoting the executable path

Low priority

The launcher stores the detected interpreter in `python_cmd` but invokes it as `$python_cmd` rather than `"$python_cmd"`.&#x20;

IPTV_Launcher.sh



This normally works when Python is found through a conventional PATH entry, but can fail if the interpreter path contains spaces.

Fix: Invoke `"$python_cmd"` consistently, including both quick-search and interactive-search paths.

4\. README claims still exceed what the tests establish

The README describes robust URL validation, correct parsing, and identical cross-platform behavior.&#x20;

README.md

&#x20;Those are reasonable goals, but syntax checks and targeted Python tests do not establish full parity across Windows Batch, PowerShell, Linux, and macOS.



Fix: Treat the documented behaviors as explicit regression-test requirements rather than considering them verified solely from code inspection.

## What is working well

- Python compilation: passed.

- Bash syntax: passed.&#x20;

- Channel names containing commas: the new title parser correctly preserves `News, International`.&#x20;

- Malformed URLs: `http://:8080/live` and an out-of-range port are rejected, while valid HTTPS and UDP examples are accepted.&#x20;

- Cache writes: the implementation uses a temporary file and atomic replacement, with cleanup on failure.

- Exit-code handling: the Python CLI reserves exit code `2` for no search matches, while translating argparse usage errors to `1`.

## Recommended release gate

### Release verification checklist

0 of 6

Validate downloaded playlists contain at least one usable channel before replacing the cache.

Test malformed downloads and confirm a previously working cache remains unchanged.

Reject sensitivity values below 0.1 and above 1.0 in both shell launchers.

Run quick-search, cancellation, no-match, missing-script, and Python-error scenarios.

Test Windows argument handling and verify VLC launches with the selected URL.

Run end-to-end tests on actual Windows, Linux, and macOS environments.

Verdict: v0.1.4 is improved, but I recommend holding the release until the playlist-validation and sensitivity-range defects are fixed. This was a static and targeted test audit; I have not verified actual VLC playback or executed the Windows launchers on Windows. I have not modified your uploaded files.