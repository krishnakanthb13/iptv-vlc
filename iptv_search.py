import sys
import os
import argparse
import difflib
import tempfile
import time
from urllib.parse import urlparse

import urllib.request as urllib_req  # Python 3

# --- CONFIGURATION ---
MASTER_URL = "https://iptv-org.github.io/iptv/index.m3u"
CACHE_FILE = os.path.join(tempfile.gettempdir(), "iptv_master_cache.m3u")
CACHE_EXPIRY = 3600 * 24  # 24 hours
DOWNLOAD_TIMEOUT = 60  # seconds
SCRIPT_VERSION = "0.1.0"

def _read_cache():
    """Read and return lines from cache if it exists, else None."""
    if not os.path.exists(CACHE_FILE):
        return None
    try:
        with open(CACHE_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            return f.readlines()
    except OSError:
        return None


def _cache_age_hours():
    """Return cache age in hours, or None if no cache."""
    if not os.path.exists(CACHE_FILE):
        return None
    age = time.time() - os.path.getmtime(CACHE_FILE)
    return int(age / 3600)


def _cache_timestamp():
    """Return cache modification timestamp as string, or None."""
    if not os.path.exists(CACHE_FILE):
        return None
    return time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(os.path.getmtime(CACHE_FILE)))


def download_m3u(force_refresh=False):
    """Downloads the master M3U list and caches it to disk for 24 hours."""
    if force_refresh and os.path.exists(CACHE_FILE):
        os.remove(CACHE_FILE)

    cache_age = _cache_age_hours()
    if cache_age is not None and cache_age * 3600 < CACHE_EXPIRY:
        lines = _read_cache()
        if lines:
            cache_time = _cache_timestamp()
            print(f"[i] Using cached playlist ({cache_age}h old, from {cache_time})")
            return lines

    print("\n[!] Downloading master channel list (30,000+ channels)...")
    start_time = time.time()
    try:
        req = urllib_req.Request(MASTER_URL, headers={"User-Agent": "iptv-vlc-launcher/1.0"})
        with urllib_req.urlopen(req, timeout=DOWNLOAD_TIMEOUT) as response:
            content = response.read().decode('utf-8', errors='ignore')
        elapsed = time.time() - start_time
        print(f"[i] Download completed in {elapsed:.1f}s")
        temp_cache = f"{CACHE_FILE}.tmp.{os.getpid()}"
        with open(temp_cache, 'w', encoding='utf-8') as f:
            f.write(content)
        os.replace(temp_cache, CACHE_FILE)
        return content.splitlines(True)
    except Exception as e:
        print(f"X Download failed: {e}", flush=True)
        if cache_age is not None:
            lines = _read_cache()
            if lines:
                print(f"[!] Falling back to cached playlist ({cache_age}h old)")
                return lines
        sys.exit(1)


def parse_m3u(lines):
    """Parses M3U lines into a list of dicts with 'name' and 'url'."""
    channels = []
    current_name = None
    for line in lines:
        line = line.strip()
        if line.startswith("#EXTINF"):
            # Name is everything after the last comma
            comma_idx = line.rfind(',')
            if comma_idx != -1:
                current_name = line[comma_idx + 1:].strip()
        elif current_name:
            parsed = urlparse(line)
            if parsed.scheme in ("http", "https"):
                channels.append({"name": current_name, "url": line})
                current_name = None
            elif not line or line.startswith("#"):
                pass
            else:
                current_name = None
        elif not line or line.startswith("#"):
            # Skip empty lines and other directives
            pass
        else:
            current_name = None
    return channels


def fuzzy_search(query, channels, threshold, limit):
    """
    Performs fuzzy search using difflib SequenceMatcher.
    Gives bonuses for exact and substring matches.
    Returns up to 'limit' results sorted by score descending.
    """
    if not query:
        return []

    results = []
    query_lower = query.lower()

    for ch in channels:
        name_lower = ch['name'].lower()

        if query_lower == name_lower:
            score = 1.0
        elif query_lower in name_lower:
            # Substring match — score based on how much of the name is covered
            score = min(0.95, 0.8 + (len(query) / max(len(name_lower), 1)) * 0.15)
        else:
            matcher = difflib.SequenceMatcher(None, query_lower, name_lower, autojunk=False)
            score = matcher.ratio()

        if score >= threshold:
            results.append((score, ch))

    results.sort(key=lambda x: x[0], reverse=True)
    return results[:limit]


def main():
    parser = argparse.ArgumentParser(description="IPTV Channel Search Engine")
    parser.add_argument("--query", help="Channel name to search (prompted if omitted)")
    parser.add_argument(
        "--threshold", type=float, default=0.7,
        help="Fuzzy search threshold 0.1 (loose) to 1.0 (exact). Default: 0.7"
    )
    parser.add_argument(
        "--output-file",
        help="File path to write the selected stream URL into (used by shell launchers)"
    )
    parser.add_argument(
        "--limit", type=int, default=50,
        help="Maximum number of results to display (default: 50)"
    )
    parser.add_argument(
        "--force-refresh", action="store_true",
        help="Force fresh download ignoring cache"
    )
    args = parser.parse_args()

    # Validate threshold
    if args.threshold < 0.1 or args.threshold > 1.0 or not (0.1 <= args.threshold <= 1.0):
        print("X Invalid threshold. Must be between 0.1 and 1.0.")
        sys.exit(1)
    if args.limit < 1:
        print("X Invalid limit. Must be >= 1.")
        sys.exit(1)

    # Prompt for query if not provided via flag
    if not args.query:
        try:
            args.query = input("\nEnter channel name to search: ").strip()
        except (EOFError, KeyboardInterrupt):
            return
    
    if not args.query:
        print("X No search query provided.")
        return

    lines = download_m3u(force_refresh=args.force_refresh)
    if not lines:
        sys.exit(1)

    channels = parse_m3u(lines)
    if not channels:
        print("X Could not parse any channels from the playlist.")
        sys.exit(1)
    print(f"[i] Loaded {len(channels)} channels")

    matches = fuzzy_search(args.query, channels, args.threshold, args.limit)

    if not matches:
        print(f"\n[!] No channels found matching '{args.query}' (sensitivity: {args.threshold})")
        print("    Try lowering the sensitivity with -T in the launcher.")
        sys.exit(1)

    print(f"\n--- Search Results (Top {len(matches)}) ---")
    for i, (score, ch) in enumerate(matches):
        print(f"{i + 1}. {ch['name']}  ({int(score * 100)}%)")
    print("0. Cancel")

    try:
        pick = input(f"\nSelect channel (1-{len(matches)}): ").strip()
    except (EOFError, KeyboardInterrupt):
        return

    if not pick or pick == '0':
        return

    try:
        idx = int(pick) - 1
        if 0 <= idx < len(matches):
            selected_url = matches[idx][1]['url']
            if args.output_file:
                # Write URL to file so the calling shell can read it non-interactively
                with open(args.output_file, 'w', encoding='utf-8') as f:
                    f.write(selected_url)
            else:
                # Fallback: print to stdout for direct use
                print(f"RESULT_URL:{selected_url}")
                sys.stdout.flush()
        else:
            print("X Invalid selection.")
    except ValueError:
        print("X Please enter a number.")


if __name__ == "__main__":
    main()
