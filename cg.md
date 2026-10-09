# IPTV Launcher — Complete Code Audit

I’ll review the five uploaded files as one application, covering correctness, edge cases, Windows/Linux compatibility, security, reliability, and maintainability. I’ll distinguish confirmed bugs from potential risks and optional improvements, rather than treating every style observation as a defect.

The key requirement is to preserve the current functionality: the 25 playlist menu options, fuzzy channel search, configurable search sensitivity, playlist caching, and VLC launching.

## 1. Audit scope

Bash launcher — Linux/macOS

VLC detection, command-line searches, menu handling, temporary files, and shell portability.

Windows batch launcher

Quick-search argument handling, command quoting, control flow, Python discovery, and error handling.

PowerShell launcher and batch wrapper

Process invocation, parameter passing, path resolution, temporary-file cleanup, and execution-policy choices.

Python search engine

Playlist parsing, network downloads, cache integrity, fuzzy matching, input validation, and result transfer.

I’ll also compare the implementations for behavioral differences and identify a sensible order for fixes, prioritizing defects that could cause incorrect results, failed launches, or data-handling problems.

## 2. Findings — highest priority first

The first round of static inspection and targeted Python tests has identified several concrete issues. The most important ones affect command-line behavior, compatibility, URL handling, and the consistency of the launchers.

High

1\. Bash launcher is incompatible with the default macOS Bash version

The script uses `${choice,,}` to lowercase menu input. This syntax requires Bash 4 or newer, whereas macOS ships with Bash 3.2 by default. Consequently, the interactive menu can fail on a standard macOS installation.

Affected: `IPTV_Launcher(5).sh`, menu input handling around line 149.

High

2\. The M3U parser accepts malformed URL schemes

The Python parser checks whether a stream line starts with `http`, rather than validating the URL scheme. A URL such as `httpx://evil.example/stream` is accepted as a channel URL in the targeted test.&#x20;



Improvement: Parse and validate URLs explicitly, allowing only intended schemes such as `http` and `https`.

High

3\. Windows quick search ignores additional unquoted arguments

The batch launcher uses `%~1` as the search query, so a command such as `IPTV_Launcher.bat BBC News` searches for `BBC`, not `BBC News`. The documented quoted form works around this limitation, but behavior differs from Bash and PowerShell, both of which combine the supplied arguments.

Affected: `IPTV_Launcher(5).bat`, quick-search section.

Medium

4\. Search failures can look like successful execution

In Bash quick-search mode, the Python exit status is not checked, and the launcher exits with status `0` even if the search fails. In PowerShell quick-search mode, the script likewise exits with `0` after invoking Python, without consistently checking its exit code.

Improvement: Propagate meaningful exit codes and print clear messages for no matches, missing dependencies, download failures, and launch failures.

Medium

5\. Playlist cache writes are not atomic

The Python downloader writes directly to the cache file. If the process is interrupted during a write, the next run may read a truncated cache. Forced refresh also removes the existing cache before the replacement download succeeds.

Improvement: Download into a temporary file, validate the contents, then replace the cache atomically. Preserve the old cache until the new one is ready.

Medium

6\. Python version compatibility is inconsistent

The search script contains a Python 2 compatibility branch, but it uses f-strings and other Python 3-specific features. The Windows help text specifies Python 3.6 or newer, which is a more realistic contract.

Improvement: Explicitly support Python 3.6+ if that is the intended minimum, or choose and test a newer minimum if needed. Remove misleading Python 2 fallback code.

These are not all equivalent in severity: the malformed-scheme issue is a validation defect, while the cache behavior is primarily a resilience concern. The fixes should be prioritized accordingly.

## 3. Python search engine: detailed audit

### Playlist parsing and search

| Area            | Finding                                                                    | Recommended change                                                                             |
| --------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| URL validation  | `startswith("http")` accepts malformed schemes                             | Use a URL parser and scheme allowlist                                                          |
| M3U state       | Channel name persists across comments and directives                       | Retain support for valid intervening directives; test malformed entries and missing URLs       |
| Name extraction | Uses the last comma in `#EXTINF`                                           | Test titles containing commas and unusual metadata                                             |
| Fuzzy matching  | Uses `SequenceMatcher` plus exact/substring bonuses                        | Test short queries, duplicate names, punctuation, and misleading substring matches             |
| Threshold       | Clamps values to 0.1–1.0                                                   | Reject invalid values rather than silently changing them; explicitly reject non-finite numbers |
| Result limit    | Accepts unrestricted integer values                                        | Require a positive limit and provide a sensible upper bound                                    |
| Selection       | Invalid numeric input is handled, but feedback and exit status are limited | Validate selection and make cancellation and errors unambiguous                                |

The fuzzy-matching approach is reasonable for a lightweight utility. I would not replace it with a heavier search library unless real-world testing shows that the current ranking is inadequate.

### Download and cache reliability

The downloader already has useful foundations: a request timeout, a user-agent header, a cache expiry, and fallback to an existing cache after a download failure.

The improvements I would make are:

1. Atomic cache replacement: write to a uniquely created temporary file in the same directory, validate it, then replace the old cache.
2. Cache validation: do not treat every non-empty file as a valid playlist. Check for a plausible M3U structure and usable entries.
3. Safer refresh behavior: keep the last usable cache when forced refresh fails.
4. Concurrency handling: avoid multiple launcher instances corrupting or overwriting the same cache.
5. Cache path safety: use a user-specific cache location or securely created cache file rather than relying on a predictable shared temporary filename.
6. Resource limits: consider a maximum download size so an unexpectedly large response cannot consume excessive memory or disk space.
7. Better errors: distinguish network timeouts, HTTP errors, invalid content, filesystem errors, and an empty playlist.

One additional improvement is to separate downloading, parsing, ranking, and user interaction into independently testable functions. Most of that separation already exists, so this can be done incrementally without a redesign.

## 4. Windows and Linux/macOS comparison

The launchers share the same general design, but they are not behaviorally identical.

| Feature                     | Bash                         | Windows batch       | PowerShell                 |
| --------------------------- | ---------------------------- | ------------------- | -------------------------- |
| Interactive menu            | Yes                          | Yes                 | Yes                        |
| Playlist options            | 1–25                         | 1–25                | 1–25                       |
| Quick search                | All arguments                | First argument only | Joins all arguments        |
| Sensitivity adjustment      | Yes                          | Yes                 | Yes                        |
| Help/about menu             | No                           | Yes                 | No                         |
| Python discovery            | `python3`, then `python`     | `python` only       | `python3`, then `python`   |
| Missing search script check | Interactive mode only        | Not consistently    | Interactive mode only      |
| Search error reporting      | Limited in quick mode        | Limited             | Better in interactive mode |
| macOS Bash 3.2 support      | A compatibility issue exists | Not applicable      | Not applicable             |

### Additional Windows findings

A. The batch wrapper does not forward arguments.

`IPTV_Launcher_ps(5).bat` runs PowerShell with `-File` but does not pass `%*`. Even if the wrapper and PowerShell filenames are correctly aligned, calling the wrapper with a channel name will not activate the PowerShell quick-search mode.

B. Delayed expansion can damage some search queries.

The Windows batch launcher enables delayed expansion globally. Exclamation marks in user-supplied arguments can be interpreted as variable expansion markers, potentially changing a query. This deserves a regression test.

C. Python discovery is inconsistent.

The batch launcher checks `python` only, while the Bash and PowerShell versions try `python3` first. A Windows machine with a working Python installation exposed under another command may fail unnecessarily.

D. Temporary-file names are not robust under concurrency.

The batch version builds its temporary filename from `%RANDOM%`. Collisions are unlikely in ordinary use but possible when several instances run concurrently. The Bash version uses `mktemp`, and PowerShell uses `GetTempFileName()`, which are better starting points.

E. VLC discovery is restrictive.

The Windows scripts look for VLC in two standard installation directories. This can miss portable installations or installations in custom locations. Searching `PATH` and supporting an explicit VLC path would make the launcher more flexible.

### PowerShell and wrapper security

The wrapper uses `-ExecutionPolicy Bypass`. This does not permanently change the machine-wide execution policy, but it weakens the execution-policy check for that PowerShell process. Prefer normal policy behavior where practical, and use an appropriately signed or otherwise trusted script when policy enforcement is required.

The PowerShell launcher also constructs a quoted argument string for `Start-Process`. Once URLs are explicitly validated, this will be easier to handle safely and consistently. The exact argument behavior should be tested on the Windows PowerShell version you intend to support.

## 5. Security and integrity assessment

This is a lightweight launcher, not a network service, so a large security framework is unnecessary. A handful of targeted safeguards would address most of the meaningful risks.

Remote playlist trust

A downloaded playlist can contain unexpected or malformed stream URLs. The launcher passes selected URLs to VLC, so validating schemes and URL structure before launch is important.

Cache integrity

Truncated, stale, or malformed cache contents should not silently become the active search database. Atomic writes, content validation, and preserving the previous good cache address this.

Temporary-file handling

Keep result files uniquely named, clean them up on failure, and avoid reading stale results. A result file should contain only one validated URL before VLC is launched.

Network failure and untrusted content

Keep network timeouts, handle HTTP errors, impose a reasonable response-size limit, and avoid interpreting an arbitrary response as a valid playlist. HTTPS for the master playlist is a good existing choice, but it does not guarantee that every stream listed within it is safe or reliable.

A URL allowlist should not be so restrictive that it breaks legitimate IPTV streams. In particular, validate the URL protocol without assuming that every stream must use HTTPS: some otherwise legitimate streams may use HTTP.

Also, a valid URL is not a guarantee that the stream is safe, licensed, or operational. The launcher can improve technical validation, but it cannot establish those properties just from the URL.

## 6. Quality improvements worth making

I would keep the architecture simple and avoid unnecessary dependencies. These are the improvements with the best balance of benefit and implementation effort.

1\. Establish a single, consistent interface

Make the launchers agree on argument handling, exit codes, supported Python versions, sensitivity limits, menu options, and error messages.

2\. Make the cache resilient

Use atomic replacement, validate cached playlists, preserve the previous cache during refresh, and handle simultaneous launcher instances safely.

3\. Harden the input/output boundary

Validate URLs, reject invalid search thresholds and result limits, validate selected results, and make temporary-file handling reliable.

4\. Add focused automated tests

Test the parser and fuzzy-search functions independently. Use mocked network responses so routine tests do not require downloading a live playlist.

5\. Make packaging predictable

Ensure the launcher, Python script, and optional wrapper filenames match their internal references. Resolve paths relative to the script, not the current working directory.

## 7. Recommended implementation order

### Audit remediation checklist

0 of 6

P0

Fix compatibility and URL validation

macOS Bash 3.2 input handling; validate http/https URLs and reject malformed schemes.

P0

Fix Windows quick search and wrapper

Forward all arguments correctly, handle exclamation marks, and align wrapper/script names.

P1

Harden cache behavior

Atomic writes, validation, refresh fallback, and concurrency safety.

P1

Standardize error handling

Consistent exit codes, dependency checks, no-match feedback, and launch failures.

P2

Add regression tests

Parser, matching, input validation, cache failures, and cross-platform behavior.

P2

Finalize documentation and release

Document minimum versions, setup, supported platforms, and troubleshooting.

&#x20;Copy remediation checklist

## 8. Verification status

The checks performed so far are limited to static inspection and targeted Python tests.

Bash syntax validation

Passed using `bash -n` on the uploaded script. This does not verify compatibility with macOS Bash 3.2.

Python compilation

Passed using Python 3.13.5. Compilation does not establish correct behavior for every input or network condition.

Targeted parser tests

Confirmed that a valid entry with an intervening directive parses correctly and that the malformed `httpx://` scheme is incorrectly accepted.

Windows runtime verification

Not performed. PowerShell and Windows batch behavior still needs testing on Windows.

## Final verdict

The project has a sensible, lightweight structure and a useful separation between the Python search engine and the platform-specific launchers. It does not need a wholesale rewrite.

The most important next step is to fix the compatibility and URL-validation defects, correct Windows argument forwarding, and strengthen cache integrity. Then add regression tests before changing the matching algorithm or introducing extra dependencies.

Scope note: This is an audit and improvement plan, not a completed patch. I have not modified your uploaded files, and I have not yet verified the launchers end-to-end against live IPTV streams or on Windows/macOS.