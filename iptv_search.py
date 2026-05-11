import sys
import os
import argparse
import difflib
import tempfile
import time

try:
    import urllib.request as urllib_req  # Python 3
except ImportError:
    import urllib2 as urllib_req  # Python 2

# --- CONFIGURATION ---
MASTER_URL = "https://iptv-org.github.io/iptv/index.m3u"
CACHE_FILE = os.path.join(tempfile.gettempdir(), "iptv_master_cache.m3u")
CACHE_EXPIRY = 3600 * 24  # 24 hours

# Compatibility for Python 2/3 input
if sys.version_info[0] < 3:
    input = raw_input

def download_m3u():
    """Downloads the master M3U list and caches it to disk for 24 hours."""
    if os.path.exists(CACHE_FILE):
        if (time.time() - os.path.getmtime(CACHE_FILE)) < CACHE_EXPIRY:
            try:
                with open(CACHE_FILE, 'r', encoding='utf-8', errors='ignore') as f:
                    return f.readlines()
            except OSError:
                pass  # Cache unreadable, fall through to re-download

    print("\n[!] Downloading master channel list (30,000+ channels)...")
    try:
        req = urllib_req.Request(MASTER_URL, headers={"User-Agent": "iptv-vlc-launcher/1.0"})
        with urllib_req.urlopen(req, timeout=30) as response:
            content = response.read().decode('utf-8', errors='ignore')
        with open(CACHE_FILE, 'w', encoding='utf-8') as f:
            f.write(content)
        return content.splitlines(keepends=True)
    except Exception as e:
        print(f"X Failed to download playlist: {e}", flush=True)
        return []


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
        elif line.startswith("http") and current_name:
            channels.append({"name": current_name, "url": line})
            current_name = None
        elif not line or line.startswith("#"):
            # Skip empty lines and other directives, but don't reset current_name
            # (some M3U files have extra tags between EXTINF and URL)
            pass
        else:
            # Non-http, non-comment line resets state
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
    args = parser.parse_args()

    # Clamp threshold to valid range
    args.threshold = max(0.1, min(1.0, args.threshold))

    # Prompt for query if not provided via flag
    if not args.query:
        try:
            args.query = input("\nEnter channel name to search: ").strip()
        except (EOFError, KeyboardInterrupt):
            return
    
    if not args.query:
        print("X No search query provided.")
        return

    lines = download_m3u()
    if not lines:
        return

    channels = parse_m3u(lines)
    if not channels:
        print("X Could not parse any channels from the playlist.")
        return

    matches = fuzzy_search(args.query, channels, args.threshold, args.limit)

    if not matches:
        print(f"\n[!] No channels found matching '{args.query}' (sensitivity: {args.threshold})")
        print("    Try lowering the sensitivity with -T in the launcher.")
        return

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
