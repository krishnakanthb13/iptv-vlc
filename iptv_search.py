import sys
import os
import argparse
import difflib
import hashlib
import tempfile
import time
from urllib.parse import urlparse

import urllib.request as urllib_req  # Python 3

# --- CONFIGURATION ---
MASTER_URL = "https://iptv-org.github.io/iptv/index.m3u"

def _cache_file():
    """User-scoped cache path so accounts don't clash on shared systems."""
    try:
        uid = str(os.getuid())  # POSIX
    except AttributeError:
        # Windows has no os.getuid; fall back to a hash of the
        # user profile path, which is unique per account.
        home = os.path.expanduser("~")
        uid = hashlib.sha256(
            home.encode("utf-8", "surrogateescape")
        ).hexdigest()[:12]
    return os.path.join(tempfile.gettempdir(), f"iptv_master_cache_{uid}.m3u")

CACHE_FILE = _cache_file()
CACHE_EXPIRY = 3600 * 24  # 24 hours
DOWNLOAD_TIMEOUT = 60  # seconds
SCRIPT_VERSION = "0.1.9"

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


def _is_valid_playlist(content):
    """Check that downloaded content looks like a real M3U playlist."""
    if not content:
        return False
    head = content.lstrip('\ufeff\r\n \t')
    first_line = head.split('\n', 1)[0].strip().upper()
    # The header may carry attributes, e.g. "#EXTM3U x-tvg-url=..."
    # but the token itself must be exactly "#EXTM3U"
    if first_line != '#EXTM3U' and not first_line.startswith(('#EXTM3U ', '#EXTM3U\t')):
        return False
    return any(
        line.lstrip().upper().startswith(('#EXTINF:', '#EXTINF ', '#EXTINF\t'))
        for line in content.splitlines()
    )


def download_m3u(force_refresh=False):
    """Downloads the master M3U list, caches it, and returns parsed channels.

    Validates downloaded content before replacing the cache, falls back to
    the previous cache when the download fails, and exits with status 1 on
    a fatal error. The cache is read from disk at most once and the
    playlist is parsed exactly once per code path.
    """
    cache_age = _cache_age_hours()
    # Read the cache once so the validity check and the fallback paths
    # share the same content instead of re-reading it from disk.
    cached_lines = _read_cache() if cache_age is not None else None

    # If not forcing refresh and cache is valid, use it
    if not force_refresh:
        if cache_age is not None and cache_age * 3600 < CACHE_EXPIRY and cached_lines:
            # NOTE: parse_m3u is the authoritative definition of a
            # "usable channel". Any change to it also changes
            # cache-validity semantics.
            channels = parse_m3u(cached_lines)
            if channels:
                cache_time = _cache_timestamp()
                print(f"[i] Using cached playlist ({cache_age}h old, from {cache_time})")
                return channels

    print("\n[!] Downloading master channel list (30,000+ channels)...")
    start_time = time.time()
    temp_cache = None
    try:
        req = urllib_req.Request(MASTER_URL, headers={"User-Agent": "iptv-vlc-launcher/1.0"})
        with urllib_req.urlopen(req, timeout=DOWNLOAD_TIMEOUT) as response:
            content = response.read().decode('utf-8', errors='ignore')
        elapsed = time.time() - start_time
        print(f"[i] Download completed in {elapsed:.1f}s")
        # Validate before touching the cache so a bad response can't poison it
        if not _is_valid_playlist(content):
            raise ValueError("downloaded content is not a valid M3U playlist")
        new_lines = content.splitlines(True)
        new_channels = parse_m3u(new_lines)
        if not new_channels:
            raise ValueError("downloaded playlist contains no usable channels")
        cache_dir = os.path.dirname(CACHE_FILE) or "."
        with tempfile.NamedTemporaryFile(
            mode='w', encoding='utf-8', dir=cache_dir,
            prefix='iptv_cache_', suffix='.tmp', delete=False
        ) as f:
            temp_cache = f.name
            f.write(content)
        os.replace(temp_cache, CACHE_FILE)
        temp_cache = None
        return new_channels
    except Exception as e:
        print(f"X Download failed: {e}", flush=True)
        # For forced refresh, keep the old cache if the download failed
        if force_refresh and cached_lines:
            old_channels = parse_m3u(cached_lines)
            if old_channels:
                print("[!] Download failed - keeping existing cached playlist")
                return old_channels
        if cached_lines:
            channels = parse_m3u(cached_lines)
            if channels:
                print(f"[!] Falling back to cached playlist ({cache_age}h old)")
                return channels
        sys.exit(1)
    finally:
        if temp_cache and os.path.exists(temp_cache):
            try:
                os.remove(temp_cache)
            except OSError:
                pass


VALID_SCHEMES = ("http", "https", "rtsp", "rtmp", "udp", "rtp", "mms")

def _extinf_title(line):
    """Return the display name from an #EXTINF line.

    The name is everything after the first comma that is not inside a
    double-quoted attribute, so names containing commas are preserved.
    """
    in_quotes = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_quotes = not in_quotes
        elif ch == ',' and not in_quotes:
            return line[i + 1:].strip()
    return None


def _is_valid_url(line):
    """True if line is a playable URL with a known scheme and hostname."""
    # Reject double quotes and exclamation marks: RFC 3986 forbids unencoded
    # quotes, and both characters break or get corrupted by Windows CMD
    # argument handling / delayed expansion in the Batch launcher.
    if '"' in line or '!' in line:
        return False
    # Reject whitespace and control characters; legitimate spaces must be
    # percent-encoded in a URL
    if any(ord(c) < 32 or c.isspace() for c in line):
        return False
    try:
        parsed = urlparse(line)
        if parsed.scheme.lower() not in VALID_SCHEMES:
            return False
        if not parsed.hostname:
            return False
        _ = parsed.port  # raises ValueError on a malformed port
    except ValueError:
        return False
    return True


def parse_m3u(lines):
    """Parses M3U lines into a list of dicts with 'name' and 'url'."""
    channels = []
    current_name = None
    for line in lines:
        line = line.strip()
        if line.upper().startswith(('#EXTINF:', '#EXTINF ', '#EXTINF\t')):
            current_name = _extinf_title(line)
        elif current_name:
            if _is_valid_url(line):
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


# Exit-code contract (all shell launchers rely on this):
#   0 = channel selected; URL written to --output-file (or stdout)
#   1 = fatal error (download failed, invalid arguments)
#   2 = no channels matched the query
#   3 = no selection (user cancelled, EOF/Ctrl+C, or invalid selection)

def main():
    parser = argparse.ArgumentParser(description="IPTV Channel Search Engine")
    parser.add_argument(
        "--version", action="version",
        version=f"iptv_search {SCRIPT_VERSION}"
    )
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
    # argparse uses exit code 2 for usage errors; we reserve 2 for "no
    # matches", so remap argparse's 2 -> 1 before it can leak out.
    try:
        args = parser.parse_args()
    except SystemExit as e:
        sys.exit(1 if e.code == 2 else e.code)

    # Validate threshold
    if not (0.1 <= args.threshold <= 1.0):
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
            print()
            sys.exit(3)

    if not args.query:
        print("X No search query provided.")
        sys.exit(3)

    channels = download_m3u(force_refresh=args.force_refresh)
    print(f"[i] Loaded {len(channels)} channels")

    matches = fuzzy_search(args.query, channels, args.threshold, args.limit)

    if not matches:
        print(f"\n[!] No channels found matching '{args.query}' (sensitivity: {args.threshold})")
        print("    Try lowering the sensitivity with T in the launcher.")
        sys.exit(2)  # Exit code 2 indicates no results, not error

    print(f"\n--- Search Results (Top {len(matches)}) ---")
    for i, (score, ch) in enumerate(matches):
        print(f"{i + 1}. {ch['name']}  ({int(score * 100)}%)")
    print("0. Cancel")

    try:
        pick = input(f"\nSelect channel (1-{len(matches)}): ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(3)

    if not pick or pick == '0':
        sys.exit(3)

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
            sys.exit(3)
    except ValueError:
        print("X Please enter a number.")
        sys.exit(3)


if __name__ == "__main__":
    main()
