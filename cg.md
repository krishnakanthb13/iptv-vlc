# IPTV VLC Launcher v0.1.11 — independent audit

Assessment: The Bash Python 3 detection fix is present, and the Python and Bash syntax checks pass. I found one remaining consistency gap in the Windows launchers: they check whether Python runs, but not whether it is Python 3.

## What I verified

- Bash Python detection: `find_python()` tries `python3` and then `python`, executes `--version`, and checks that the major version is at least 3. Both search paths reuse it.&#x20;

  IPTV_Launcher.sh

- Batch exit-code capture: the quick-search path captures `%errorlevel%` before `endlocal` and transfers it to `PY_EXIT`. Empty output after a reported success is treated as an error.&#x20;

- Python robustness: the Unicode stream reconfiguration now catches `OSError` as well as `AttributeError` and `ValueError`. The playlist parser and URL validation retain the strict `#EXTINF` delimiters and reject quotes and exclamation marks.&#x20;

  iptv_search.py

- Documentation and versions: the README identifies v0.1.11 and documents Unicode-safe output. The five main project files I checked consistently report `0.1.11`; the wrapper batch file does not contain a version string.&#x20;

  README.md



Independent checks also passed: `py_compile` for the uploaded Python file and `bash -n` for the Bash launcher.&#x20;



## Remaining finding

P3 — Windows Python detection does not confirm Python 3.

Both Windows launchers accept a candidate if `--version` exits successfully:

- Batch: checks the exit code, but not the reported version.&#x20;

- PowerShell: uses the same functional-execution test in quick-search and interactive search.&#x20;



If `python3` is unavailable and `python` resolves to Python 2, either launcher may select it and then fail when the Python 3 search script runs.

Recommended fix: apply the same major-version validation used by Bash to both Windows launchers. Parse the version output and accept only Python 3 or later; continue to the next candidate if the version is missing, malformed, or unsupported. Keep the existing execution check, since it also catches broken Microsoft Store aliases.

## Release recommendation

I’d consider v0.1.11 close to release-ready, with this Windows version check as the final hardening item.

I could not independently run PowerShell syntax validation or native Windows end-to-end tests in this environment because neither `pwsh` nor `powershell` is available. That does not invalidate your reported Windows tests; it limits what I can independently confirm here.

After the Windows version check is fixed and tested, I’d be comfortable recommending the commit, while retaining regression tests for Python detection, special-character queries, Unicode output, empty result files, and exit-code handling.