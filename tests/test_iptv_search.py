import os
import sys
import tempfile
import unittest

# Ensure the repository root is on sys.path
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

import iptv_search


class TestUrlValidation(unittest.TestCase):
    def test_valid_urls(self):
        valid = [
            "http://example.com/stream.m3u8",
            "https://cdn.example.org:8080/live/ch1.ts",
            "rtsp://192.168.1.100:554/live",
            "rtmp://live.stream.net/app/channel",
            "udp://@239.255.1.1:5000",
            "rtp://@239.255.1.2:5000",
            "mms://media.example.com/broadcast",
            "http://example.com/path%20with%20encoded%20spaces",
        ]
        for url in valid:
            self.assertTrue(iptv_search._is_valid_url(url), f"Expected valid: {url}")

    def test_invalid_schemes(self):
        invalid = [
            "ftp://example.com/file",
            "file:///C:/test.m3u",
            "javascript:alert(1)",
            "data:text/plain;base64,SGVsbG8=",
            "gopher://example.com",
        ]
        for url in invalid:
            self.assertFalse(iptv_search._is_valid_url(url), f"Expected invalid scheme: {url}")

    def test_missing_host(self):
        self.assertFalse(iptv_search._is_valid_url("http://"))
        self.assertFalse(iptv_search._is_valid_url("https:///path"))

    def test_double_quote_rejection(self):
        # Double quotes are forbidden by RFC 3986 and dangerous in Batch launcher
        malicious = [
            'http://example.com/"&calc.exe',
            'http://example.com/live"stream',
            '"http://example.com/live"',
        ]
        for url in malicious:
            self.assertFalse(iptv_search._is_valid_url(url), f"Expected quote rejection: {url}")

    def test_exclamation_mark_rejection(self):
        # Exclamation marks corrupt CMD delayed expansion
        malicious = [
            "http://example.com/!test!",
            "http://example.com/live!stream",
            "!http://example.com/live",
        ]
        for url in malicious:
            self.assertFalse(iptv_search._is_valid_url(url), f"Expected ! rejection: {url}")

    def test_whitespace_and_control_chars(self):
        invalid = [
            "http://example.com/live stream",
            "http://example.com/live\tstream",
            "http://example.com/live\nstream",
            "http://example.com/\x01stream",
        ]
        for url in invalid:
            self.assertFalse(iptv_search._is_valid_url(url), f"Expected whitespace/ctrl rejection: {url}")

    def test_malformed_ports(self):
        self.assertFalse(iptv_search._is_valid_url("http://example.com:abc/live"))
        self.assertFalse(iptv_search._is_valid_url("http://example.com:9999999/live"))


class TestPlaylistValidation(unittest.TestCase):
    def test_valid_playlists(self):
        valid = [
            "#EXTM3U\n#EXTINF:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "#EXTM3U x-tvg-url=\"http://epg.xml\"\n#EXTINF:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "#extm3u\n#extinf:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "#EXTM3U\n#EXTINF -1,Channel 1\nhttp://example.com/ch1.m3u8",
            "#EXTM3U\n#EXTINF\t-1,Channel 1\nhttp://example.com/ch1.m3u8",
        ]
        for p in valid:
            self.assertTrue(iptv_search._is_valid_playlist(p), f"Expected valid playlist: {p[:30]}")

    def test_invalid_header(self):
        invalid = [
            "#EXTM3Ufoo\n#EXTINF:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "#EXTM3U-EXT\n#EXTINF:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "EXTM3U\n#EXTINF:-1,Channel 1\nhttp://example.com/ch1.m3u8",
            "Not a playlist at all",
            "",
        ]
        for p in invalid:
            self.assertFalse(iptv_search._is_valid_playlist(p), f"Expected invalid header: {p[:30]}")

    def test_missing_or_spoofed_extinf(self):
        invalid = [
            "#EXTM3U\nhttp://example.com/ch1.m3u8",  # No #EXTINF
            "#EXTM3U\n#SOMETHING #EXTINF:-1,Spoof\nhttp://example.com/ch1.m3u8",  # Mid-line #EXTINF
        ]
        for p in invalid:
            self.assertFalse(iptv_search._is_valid_playlist(p))


class TestExtinfTitle(unittest.TestCase):
    def test_simple_title(self):
        self.assertEqual(iptv_search._extinf_title("#EXTINF:-1,CNN International"), "CNN International")
        self.assertEqual(iptv_search._extinf_title("#EXTINF:0,BBC News"), "BBC News")

    def test_attributes_with_commas(self):
        line = '#EXTINF:-1 tvg-id="cnn" group-title="News, Current Affairs",CNN International'
        self.assertEqual(iptv_search._extinf_title(line), "CNN International")

    def test_attributes_with_escaped_quotes(self):
        line = '#EXTINF:-1 tvg-name="Channel \\"Special\\", 1",Channel 1'
        self.assertEqual(iptv_search._extinf_title(line), "Channel 1")

    def test_title_with_commas(self):
        line = '#EXTINF:-1,Channel 1, The Sequel'
        self.assertEqual(iptv_search._extinf_title(line), "Channel 1, The Sequel")

    def test_no_comma(self):
        self.assertIsNone(iptv_search._extinf_title("#EXTINF:-1 Channel Without Comma"))


class TestParseM3u(unittest.TestCase):
    def test_parse_valid_lines(self):
        lines = [
            "#EXTM3U",
            '#EXTINF:-1 tvg-id="1",Channel One',
            "http://example.com/ch1.m3u8",
            "",
            "# A comment",
            "#EXTVLCOPT:network-caching=1000",
            '#EXTINF:-1 tvg-id="2",Channel Two',
            "https://example.com/ch2.m3u8",
        ]
        channels = iptv_search.parse_m3u(lines)
        self.assertEqual(len(channels), 2)
        self.assertEqual(channels[0]["name"], "Channel One")
        self.assertEqual(channels[0]["url"], "http://example.com/ch1.m3u8")
        self.assertEqual(channels[1]["name"], "Channel Two")
        self.assertEqual(channels[1]["url"], "https://example.com/ch2.m3u8")

    def test_reject_invalid_channel_url(self):
        lines = [
            "#EXTM3U",
            "#EXTINF:-1,Bad Channel",
            'http://example.com/"&calc.exe',
            "#EXTINF:-1,Good Channel",
            "http://example.com/good.m3u8",
        ]
        channels = iptv_search.parse_m3u(lines)
        self.assertEqual(len(channels), 1)
        self.assertEqual(channels[0]["name"], "Good Channel")


class TestFuzzySearch(unittest.TestCase):
    def setUp(self):
        self.channels = [
            {"name": "CNN International", "url": "http://example.com/cnn"},
            {"name": "BBC News", "url": "http://example.com/bbc"},
            {"name": "Sky News", "url": "http://example.com/sky"},
            {"name": "Al Jazeera English", "url": "http://example.com/alj"},
        ]

    def test_exact_match(self):
        results = iptv_search.fuzzy_search("BBC News", self.channels, threshold=0.7, limit=10)
        self.assertTrue(len(results) >= 1)
        best_score, best_ch = results[0]
        self.assertEqual(best_ch["name"], "BBC News")
        self.assertEqual(best_score, 1.0)

    def test_substring_match(self):
        results = iptv_search.fuzzy_search("BBC", self.channels, threshold=0.7, limit=10)
        self.assertTrue(len(results) >= 1)
        best_score, best_ch = results[0]
        self.assertEqual(best_ch["name"], "BBC News")
        self.assertTrue(best_score >= 0.8)

    def test_empty_query(self):
        results = iptv_search.fuzzy_search("", self.channels, threshold=0.7, limit=10)
        self.assertEqual(results, [])

    def test_threshold_filtering(self):
        results = iptv_search.fuzzy_search("XYZ NonExistent Channel", self.channels, threshold=0.8, limit=10)
        self.assertEqual(results, [])

    def test_limit(self):
        channels = [{"name": f"Channel {i}", "url": f"http://example.com/{i}"} for i in range(50)]
        results = iptv_search.fuzzy_search("Channel", channels, threshold=0.1, limit=5)
        self.assertEqual(len(results), 5)


class TestCachePath(unittest.TestCase):
    def test_cache_filename(self):
        cache_path = iptv_search._cache_file()
        basename = os.path.basename(cache_path)
        self.assertTrue(basename.startswith("iptv_master_cache_"))
        self.assertTrue(basename.endswith(".m3u"))


class TestCli(unittest.TestCase):
    def test_version_flag(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, os.path.join(REPO_ROOT, "iptv_search.py"), "--version"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertIn("0.1.12", proc.stdout)

    def test_no_match_exit_code(self):
        import subprocess
        with tempfile.NamedTemporaryFile(suffix=".txt", delete=False) as tf:
            out_file = tf.name
        try:
            # Querying for random gibberish with a high threshold will yield no matches and exit 2
            proc = subprocess.run(
                [
                    sys.executable,
                    os.path.join(REPO_ROOT, "iptv_search.py"),
                    "--query",
                    "qwertyuiopasdfghjklzxcvbnm_nonexistent_12345",
                    "--threshold",
                    "0.99",
                    "--output-file",
                    out_file,
                ],
                capture_output=True,
                text=True,
            )
            # Exit code 2 = no match found
            self.assertEqual(proc.returncode, 2)
        finally:
            if os.path.exists(out_file):
                os.remove(out_file)


if __name__ == "__main__":
    unittest.main()
