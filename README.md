# IPTV VLC Launcher v0.1.12

<p align="center">
  <img src="assets/screenshot.jpg" width="600" alt="IPTV VLC Launcher">
</p>

A lightweight, menu-driven PowerShell, Batch, and Bash launcher for streaming global IPTV playlists directly in VLC Media Player, categorized by region, language, and genre. Features a **Global Fuzzy Search Engine** with smart caching.

## Why and What it is Created For

**What it is:** A simple command-line interface tool that provides an interactive menu with 25 distinct streaming options, plus a cross-platform search engine.
**Why it was created:** It simplifies the process of accessing thousands of free, publicly available live TV channels from around the world (sourced from `iptv-org/iptv`). Instead of manually hunting for `.m3u` URLs, this tool automates the process. You pick a category or search for a specific channel, and the script launches VLC instantly.

## Features

- **Global Channel Search (`S`)**: Search through 30,000+ channels across all categories.
- **Fuzzy Matching**: Intelligent matching that handles typos and partial names.
- **Search Sensitivity (`T`)**: Adjust the fuzzy logic sensitivity (0.1 to 1.0).
- **Quick Search from CLI**: Pass a query directly as a command-line argument to skip the menu.
- **CLI Flags**: Full `--version` / `-v` and `--help` / `-h` support across all launchers.
- **Smart Caching**: Downloads the 30k master list once, caches it in a user-scoped temp file using atomic writes for 24 hours with age display and network failure fallback. A forced refresh never destroys a working cache.
- **Robust URL & Input Validation**: Strict scheme and hostname checks; rejects dangerous double quotes `"` (preventing CMD injection), exclamation marks `!` (preventing delayed expansion corruption), and malformed ports or whitespace.
- **Unicode-Safe Output**: Channel names or queries the console codepage cannot represent are replaced rather than crashing the search.
- **Force Refresh**: Bypass the cache with `--force-refresh`.
- **Channel Count**: Shows how many channels were loaded after parsing.
- **Download Timing**: Displays elapsed time for fresh downloads.
- **Help Screen (`H`)**: Built-in help with usage examples (Batch launcher).
- **Cross-Platform Parity**: Consistent menu, search, sensitivity, and caching behavior on Windows (PowerShell/Batch), Linux, and macOS (Bash). Fully supports macOS default Bash 3.2 and Windows multi-word arguments.
- **Automated Test Suite & CI**: Built-in `unittest` test suite with GitHub Actions multi-platform CI matrix on Ubuntu and Windows across Python 3.8–3.12.

## How to Use It

### Prerequisites
- **VLC Media Player** must be installed.
- **Python 3.6+** must be installed to use the search engine (`S`).

### Running the Launcher

1. **PowerShell Edition `IPTV_Launcher.ps1` (Windows -- Recommended)**:
   - Open PowerShell and execute: `.\IPTV_Launcher.ps1`
   - Features a modern, multi-colored interface and robust Python detection.

2. **Batch Edition `IPTV_Launcher.bat` (Windows)**:
   - Simply double-click on `IPTV_Launcher.bat` to run.
   - Includes a built-in help screen (`H`).

3. **PowerShell Wrapper `IPTV_Launcher_ps.bat` (Windows)**:
   - Double-click to launch the PowerShell edition with execution policy bypassed.
   - Useful on systems where PowerShell scripts cannot be run directly.

4. **Bash Edition `IPTV_Launcher.sh` (Linux / macOS)**:
   - Make it executable: `chmod +x IPTV_Launcher.sh`
   - Then run it: `./IPTV_Launcher.sh`

### Quick Search & CLI Flags

Skip the menu and search directly by passing a channel name as an argument, or pass `--version` / `-v` or `--help` / `-h`:

```bash
# Windows (Batch)
IPTV_Launcher.bat "BBC News"
IPTV_Launcher.bat --version

# Windows (PowerShell)
.\IPTV_Launcher.ps1 "CNN"
.\IPTV_Launcher.ps1 --version

# Linux / macOS
./IPTV_Launcher.sh "Discovery"
./IPTV_Launcher.sh --version
```

### Running Tests

Run the complete automated test suite using Python's built-in `unittest`:

```bash
python -m unittest discover -s tests -v
```

### Interactive Menu

- **Categories (1-25)**: Pick a category to load its entire playlist into VLC.
- **Search Channel (S)**: Enter a channel name (e.g., "BBC", "HBO", "Tamil"). The engine will display the top 50 matches. Select a result to play it instantly.
- **Adjust Sensitivity (T)**: Set a value between `0.1` (loose/broad results) and `1.0` (strict/exact matches). Default is `0.7`.
- **Help (H)**: Show usage information and keyboard shortcuts (Batch launcher).
- **Exit (0)**: Closes the launcher.

### Force Refresh

Note: force refresh is currently only available via the Python CLI, not through the menu launchers. A failed forced refresh keeps the previous cache as a fallback.

To bypass the 24-hour cache and force a fresh download:

```bash
python iptv_search.py --query "Discovery" --force-refresh
```

## Code Functionality Documentation

### 1. Global Search Engine (`iptv_search.py`)

- **M3U Parsing**: Correctly parses `EXTINF` tags even when channel names contain commas, and handles escaped quotes (`\"`) inside attributes without corrupting parsed tags.
- **Security Hardening**: Rejects dangerous double quotes `"` (command injection defense) and exclamation marks `!` (CMD delayed expansion corruption defense), as well as control characters and unencoded whitespace. Validates schemes (`http`, `https`, `rtsp`, `rtmp`, `udp`, `rtp`, `mms`) and hostnames.
- **Fuzzy Logic**: Utilizes `difflib.SequenceMatcher` with scoring bonuses for exact and substring matches.
- **Smart Caching**: Caches the master M3U list to a user-scoped temp file using atomic writes for 24 hours. Displays cache age and timestamp when using cached data. Falls back to cache automatically on network failure, including during a forced refresh.
- **Force Refresh**: `--force-refresh` downloads fresh data while keeping the previous cache as a fallback.
- **Download Timing**: Shows elapsed time for fresh downloads.
- **Channel Count**: Displays total channels loaded after parsing.
- **Network Timeout**: Configurable download timeout (default 60 seconds).

### 2. VLC Auto-Detection

The scripts automatically locate VLC at standard 64-bit and 32-bit installation paths across Windows, Linux, and macOS. VLC detection runs independently in quick search mode to handle direct CLI invocations.

### 3. Cross-Shell IPC

To allow the Python search engine to run interactively while communicating the selected stream back to the shell, the launchers use a "side-channel" temporary file method. This ensures that search prompts are visible to the user across all terminal types. Each instance gets its own collision-resistant filename (Batch generates a unique name and never reuses or deletes an existing one; PowerShell and Bash use the OS temp-file APIs `GetTempFileName` / `mktemp`).

### 4. Python Detection

All three launchers (PowerShell, Batch, and Bash) validate Python candidates by executing `--version` and verifying that the major version is >= 3. This reliably bypasses the dummy Microsoft Store Python alias on Windows and ignores legacy Python 2 or broken installations found on PATH.

### 5. Exit Codes

`iptv_search.py` follows a documented exit-code contract that every launcher relies on:

| Code | Meaning |
|------|---------|
| 0 | Channel selected — URL written to `--output-file` (or `RESULT_URL:` on stdout) |
| 1 | Fatal error (download failed, invalid arguments) |
| 2 | No channels matched the query |
| 3 | No selection (user cancelled, EOF/Ctrl+C, or invalid selection) |

In quick-search mode (`launcher "query"`), exit codes 2 and 3 are benign and the launcher exits 0, since nothing was launched and no error occurred. If Python reports success (0) but produces no URL, the launcher prints a diagnostic and exits 1. Interactive mode shows a message for each outcome.

---

*Powered by [iptv-org](https://github.com/iptv-org/iptv)*
