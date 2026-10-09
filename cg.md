# IPTV Launcher v0.1.3 — Revision 7 Audit

This revision addresses several of the earlier findings. The Python search engine now preserves the old cache for a failed forced refresh, supports additional VLC stream protocols, and returns exit code `2` for no search results. The Bash launcher also checks the Python result and uses a Bash 3.2-compatible approach to lowercase menu input.

The revision is improved, but a few integrity and cross-platform issues remain. I’m focusing on whether the implementation actually satisfies the README’s claims, not just whether the files compile.

## 1. Verification so far

Python compilation

Passed with the available Python interpreter.

Bash syntax

Passed with `bash -n`; macOS runtime compatibility still requires an actual Bash 3.2 test.

Forced-refresh fallback

The previous cache is retained in memory and returned if the download raises an exception.

Windows and live-stream testing

Not yet verified by executing the batch and PowerShell launchers on Windows or opening live streams in VLC.

## 2. Confirmed remaining findings

High

A. Channel names containing commas are truncated

The parser uses `line.rfind(',')`, which returns only the text after the last comma. My test with `News, International` returned just `International`.&#x20;



Fix: Identify the `EXTINF` separator outside quoted attributes and preserve the entire display name. This also brings the implementation into line with the README's claim about comma-containing names.

Medium

B. Hostname validation is still incomplete

The parser checks `parsed.netloc`, but that field can be non-empty even when the hostname is missing. The test accepted `http://:8080/live` as a channel URL.&#x20;



Fix: Require a non-empty `parsed.hostname`, reject malformed ports, and handle parsing exceptions. Keep the supported protocol list configurable or clearly documented.

Medium

C. A successful HTTP response can still poison the cache

The downloader atomically replaces the cache after writing the response, but it does not validate the downloaded content before replacement. A server or proxy returning an HTML error page with HTTP status 200 could replace a working playlist.

Fix: Validate that the downloaded content has a plausible M3U header and usable entries before replacing the existing cache. Clean up temporary files on failure.

Medium

D. Batch mode can mistake a missing Python script for a successful no-result search

The quick-search branch in `IPTV_Launcher(7).bat` invokes `iptv_search.py` without first checking that the file exists. It then treats exit code `2` as benign. Python can also return code `2` for command-line usage errors or a missing script.

Fix: Check the script's existence before invocation and distinguish no matches from actual execution errors. A dedicated no-match exit code should not collide with Python's normal argument-parsing error code.

Low

E. Cache temporary-file handling can be stronger

The cache temporary filename is predictable and based on the process ID. Atomic replacement is a good improvement, but secure temporary-file creation, cleanup, and validation would provide better protection against stale files and unexpected filesystem conditions.

## 3. Regression tests to add

These should be automated before the next release.

### Next-release test checklist

0/10

Preserve complete channel names containing commas.

Reject HTTP URLs without a hostname or with an invalid port.

Accept valid HTTP, HTTPS, RTSP and other explicitly supported schemes.

Retain the previous cache when forced refresh fails.

Retain the previous cache when a server returns invalid playlist content.

Handle interrupted writes and remove abandoned temporary files.

Return distinct outcomes for no matches, cancellation and execution errors.

Handle missing Python scripts and missing VLC installations.

Verify multi-word Windows queries and queries containing exclamation marks.

Verify all 25 menu options and case-insensitive menu commands.

&#x20;Copy test checklist

## 4. Release recommendation

The latest version is moving in the right direction, and the basic syntax checks pass. The most important remaining work is:

1. Fix M3U title parsing.
2. Strengthen URL validation.
3. Validate downloaded playlists before replacing the cache.
4. Correct batch missing-script and exit-code handling.
5. Add regression tests for the behaviors above.

The README should continue to describe only functionality verified in the code and tests. In particular, “cross-platform parity” and “robust URL validation” should be treated as release criteria, not assumed outcomes.&#x20;

README.md



I have not modified your uploaded files. This is a review of revision 7; Windows runtime behavior, macOS Bash 3.2 execution, and live VLC playback remain unverified.