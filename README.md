# IPTV VLC Launcher

<p align="center">
  <img src="assets/release_v0.0.4.png" width="600" alt="IPTV VLC Launcher v0.0.4">
</p>

A lightweight, menu-driven PowerShell, Batch, and Bash launcher for streaming global IPTV playlists directly in VLC Media Player, categorized by region, language, and genre. Now features a **Global Fuzzy Search Engine**!

## Why and What it is Created For

**What it is:** A simple command-line interface tool that provides an interactive menu with 25 distinct streaming options, plus a cross-platform search engine.
**Why it was created:** It simplifies the process of accessing thousands of free, publicly available live TV channels from around the world (sourced from `iptv-org/iptv`). Instead of manually hunting for `.m3u` URLs, this tool automates the process. You pick a category or search for a specific channel, and the script launches VLC instantly.

## Key New Features 🚀

- **Global Channel Search (`S`)**: Search through 30,000+ channels across all categories.
- **Fuzzy Matching**: Intelligent matching that handles typos and partial names.
- **Search Sensitivity (`T`)**: Adjust the "fuzzy" logic sensitivity (0.1 to 1.0) to find exact or loosely matched names.
- **Smart Caching**: The search engine downloads the 30k master list once and caches it for 24 hours to ensure high performance without redundant downloads.
- **Cross-Platform Parity**: The search engine works identically on Windows (PowerShell/Batch), Linux, and macOS (Bash).

## How to Use It

### Prerequisites
- **VLC Media Player** must be installed.
- **Python 3.x (Recommended)** or Python 2.7 must be installed to use the search engine (`S`).

### Running the Launcher
Choose the script that matches your operating system:

1. **PowerShell Edition `IPTV_Launcher.ps1` (Windows — Recommended)**:
   - Open PowerShell and execute: `.\IPTV_Launcher.ps1`
   - Features a modern, multi-colored interface and robust Python detection.

2. **Batch Edition `IPTV_Launcher.bat` (Windows)**:
   - Simply double-click on `IPTV_Launcher.bat` to run.

3. **Bash Edition `IPTV_Launcher.sh` (Linux / macOS)**:
   - Make it executable: `chmod +x IPTV_Launcher.sh`
   - Then run it: `./IPTV_Launcher.sh`

### Using Search and Navigation
- **Categories (1-25)**: Pick a category to load its entire playlist into VLC.
- **Search Channel (S)**: Enter a channel name (e.g., "BBC", "HBO", "Tamil"). The engine will display the top 50 matches. Select a result to play it instantly.
- **Adjust Sensitivity (T)**: Set a value between `0.1` (loose/broad results) and `1.0` (strict/exact matches). Default is `0.7`.
- **Exit (0)**: Closes the launcher.

## Code Functionality Documentation

### 1. Global Search Engine (`iptv_search.py`)
A centralized Python script handles the heavy lifting for the search feature:
- **M3U Parsing**: Correctly parses `EXTINF` tags, even when channel names contain commas.
- **Fuzzy Logic**: Utilizes `difflib.SequenceMatcher` with scoring bonuses for exact and substring matches.
- **Efficiency**: Implements system-level temp file caching for the master M3U list.

### 2. VLC Auto-Detection
The scripts automatically locate VLC at standard 64-bit and 32-bit installation paths across Windows, Linux, and macOS.

### 3. Cross-Shell IPC
To allow the Python search engine to run interactively while communicating the selected stream back to the shell, the launchers use a "side-channel" temporary file method. This ensures that search prompts are visible to the user across all terminal types.

---
*Powered by [iptv-org](https://github.com/iptv-org/iptv)*
