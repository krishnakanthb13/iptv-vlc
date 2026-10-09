#!/bin/bash
# IPTV VLC Launcher - Bash Edition

# --- CONFIGURATION ---
FUZZY_THRESHOLD=0.7
SCRIPT_VERSION="0.1.12"
# ---------------------

# Detect VLC
if command -v vlc &>/dev/null; then
    VLC="vlc"
elif [ -f "/usr/bin/vlc" ]; then
    VLC="/usr/bin/vlc"
elif [ -f "/Applications/VLC.app/Contents/MacOS/VLC" ]; then
    VLC="/Applications/VLC.app/Contents/MacOS/VLC"
else
    echo "X VLC not found. Please install VLC Media Player."
    exit 1
fi

# Resolve the directory of this script regardless of how it's called
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEARCH_SCRIPT="$SCRIPT_DIR/iptv_search.py"

# Shared Python 3 detection for both search paths. Each candidate is
# verified by actually running --version, so a Python 2 or broken
# executable found on PATH is never selected.
find_python() {
    local candidate path ver major
    for candidate in python3 python; do
        path=$(command -v "$candidate" 2>/dev/null) || continue
        ver=$("$path" --version 2>&1) || continue
        major=$(printf '%s' "$ver" | sed -n 's/^Python \([0-9][0-9]*\).*/\1/p')
        if [ -n "$major" ] && [ "$major" -ge 3 ] 2>/dev/null; then
            printf '%s\n' "$path"
            return 0
        fi
    done
    return 1
}

# Quick search: if a query was passed as argument, skip menu
if [ $# -gt 0 ]; then
    query="$*"
    python_cmd=$(find_python)
    if [ -z "$python_cmd" ]; then
        echo -e "\e[31mX Python 3 not found.\e[0m"
        exit 1
    fi
    if [ ! -f "$SEARCH_SCRIPT" ]; then
        echo -e "\e[31mX iptv_search.py not found.\e[0m"
        exit 1
    fi
    result_file=$(mktemp)
    "$python_cmd" "$SEARCH_SCRIPT" --query "$query" --threshold "$FUZZY_THRESHOLD" --output-file "$result_file"
    py_exit=$?
    url=$(cat "$result_file" 2>/dev/null)
    rm -f "$result_file"
    if [ "$py_exit" -eq 0 ]; then
        if [ -n "$url" ]; then
            "$VLC" "$url" &
            exit 0
        else
            echo -e "\e[33mX No channel URL was produced.\e[0m"
            exit 1
        fi
    fi
    # Exit codes 2 (no matches) and 3 (no selection)
    # are benign outcomes for a CLI invocation
    if [ "$py_exit" -eq 2 ] || [ "$py_exit" -eq 3 ]; then
        exit 0
    fi
    exit $py_exit
fi

# URL Map (works on Bash 3.2+ without associative arrays)
get_url() {
    case "$1" in
        1)  echo "https://iptv-org.github.io/iptv/index.m3u" ;;
        2)  echo "https://iptv-org.github.io/iptv/index.category.m3u" ;;
        3)  echo "https://iptv-org.github.io/iptv/index.language.m3u" ;;
        4)  echo "https://iptv-org.github.io/iptv/index.country.m3u" ;;
        5)  echo "https://iptv-org.github.io/iptv/countries/in.m3u" ;;
        6)  echo "https://iptv-org.github.io/iptv/countries/us.m3u" ;;
        7)  echo "https://iptv-org.github.io/iptv/languages/tam.m3u" ;;
        8)  echo "https://iptv-org.github.io/iptv/languages/tel.m3u" ;;
        9)  echo "https://iptv-org.github.io/iptv/languages/eng.m3u" ;;
        10) echo "https://iptv-org.github.io/iptv/regions/amer.m3u" ;;
        11) echo "https://iptv-org.github.io/iptv/regions/cenamer.m3u" ;;
        12) echo "https://iptv-org.github.io/iptv/regions/noram.m3u" ;;
        13) echo "https://iptv-org.github.io/iptv/regions/southam.m3u" ;;
        14) echo "https://iptv-org.github.io/iptv/categories/animation.m3u" ;;
        15) echo "https://iptv-org.github.io/iptv/categories/comedy.m3u" ;;
        16) echo "https://iptv-org.github.io/iptv/categories/cooking.m3u" ;;
        17) echo "https://iptv-org.github.io/iptv/categories/documentary.m3u" ;;
        18) echo "https://iptv-org.github.io/iptv/categories/education.m3u" ;;
        19) echo "https://iptv-org.github.io/iptv/categories/entertainment.m3u" ;;
        20) echo "https://iptv-org.github.io/iptv/categories/movies.m3u" ;;
        21) echo "https://iptv-org.github.io/iptv/categories/news.m3u" ;;
        22) echo "https://iptv-org.github.io/iptv/categories/science.m3u" ;;
        23) echo "https://iptv-org.github.io/iptv/categories/series.m3u" ;;
        24) echo "https://iptv-org.github.io/iptv/categories/sports.m3u" ;;
        25) echo "https://iptv-org.github.io/iptv/categories/music.m3u" ;;
        *)  return 1 ;;
    esac
}

show_menu() {
    clear
    echo -e "\e[36m========================================================================\e[0m"
    echo -e "\e[32m                     IPTV VLC Launcher v$SCRIPT_VERSION\e[0m"
    echo -e "\e[36m========================================================================\e[0m"
    echo -e "\e[33mVLC:\e[0m $VLC   \e[33mSensitivity:\e[0m $FUZZY_THRESHOLD"
    echo -e "\e[36m------------------------------------------------------------------------\e[0m"
    echo ""
    echo -e "\e[35m  INDEX / COUNTRIES / REGIONS          CATEGORIES\e[0m"
    echo -e "\e[90m  ------------------------------------ ---------------------------\e[0m"
    echo -e "\e[33m  1.\e[0m All Channels (Master)             \e[33m14.\e[0m Animation"
    echo -e "\e[33m  2.\e[0m Categories (Index)                \e[33m15.\e[0m Comedy"
    echo -e "\e[33m  3.\e[0m Languages (Index)                 \e[33m16.\e[0m Cooking"
    echo -e "\e[33m  4.\e[0m Countries (Index)                 \e[33m17.\e[0m Documentary"
    echo -e "                                       \e[33m18.\e[0m Education"
    echo -e "\e[33m  5.\e[0m India                             \e[33m19.\e[0m Entertainment"
    echo -e "\e[33m  6.\e[0m United States                     \e[33m20.\e[0m Movies"
    echo -e "\e[33m  7.\e[0m Tamil                             \e[33m21.\e[0m News"
    echo -e "\e[33m  8.\e[0m Telugu                            \e[33m22.\e[0m Science"
    echo -e "\e[33m  9.\e[0m English                           \e[33m23.\e[0m Series"
    echo -e "                                       \e[33m24.\e[0m Sports"
    echo -e "\e[33m 10.\e[0m Americas (All)                    \e[33m25.\e[0m Music"
    echo -e "\e[33m 11.\e[0m Central America"
    echo -e "\e[33m 12.\e[0m North America"
    echo -e "\e[33m 13.\e[0m South America"
    echo ""
    echo -e "\e[32m  S.\e[0m SEARCH CHANNEL                   \e[32m  T.\e[0m ADJUST SENSITIVITY"
    echo -e "\e[31m  0.\e[0m Exit"
    echo ""
    echo -e "\e[36m========================================================================\e[0m"
}

do_search() {
    local python_cmd
    python_cmd=$(find_python)
    if [ -z "$python_cmd" ]; then
        echo -e "\e[31mX Python 3 not found. Please install Python 3 to use search.\e[0m"
        read -r -p "Press Enter to continue..."
        return
    fi

    if [ ! -f "$SEARCH_SCRIPT" ]; then
        echo -e "\e[31mX iptv_search.py not found in: $SCRIPT_DIR\e[0m"
        read -r -p "Press Enter to continue..."
        return
    fi

    local result_file
    result_file=$(mktemp)
    # Run Python interactively; it writes the selected URL to the temp file
    "$python_cmd" "$SEARCH_SCRIPT" --threshold "$FUZZY_THRESHOLD" --output-file "$result_file"
    local py_exit=$?

    local url
    url=$(cat "$result_file" 2>/dev/null)
    rm -f "$result_file"

    if [ "$py_exit" -ne 0 ] && [ "$py_exit" -ne 2 ] && [ "$py_exit" -ne 3 ]; then
        echo -e "\e[31mX Search engine failed (exit $py_exit).\e[0m"
        read -r -p "Press Enter to continue..."
        return
    fi
    if [ "$py_exit" -eq 2 ]; then
        # No matches - Python already printed "No channels found"
        sleep 2
        return
    fi
    if [ "$py_exit" -eq 3 ] || { [ "$py_exit" -eq 0 ] && [ -z "$url" ]; }; then
        echo -e "\e[33mNo channel was selected.\e[0m"
        sleep 1
        return
    fi

    if [ -n "$url" ]; then
        echo -e "\e[32mLaunching VLC...\e[0m"
        "$VLC" "$url" &
        sleep 1
    fi
}

while true; do
    show_menu
    read -r -p "Select option: " choice

    # Trim whitespace
    choice="${choice//[[:space:]]/}"
    [ -z "$choice" ] && continue

    # Case-insensitive match (compatible with Bash 3.2 and 4+)
    choice_lc="$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')"
    case "$choice_lc" in  # lowercase for case-insensitive match
        0) echo -e "\e[32mGoodbye!\e[0m"; break ;;
        s) do_search ;;
        t)
            read -r -p "Enter new sensitivity (0.1 - 1.0): " t
            # Validate: must be a number between 0.1 and 1.0
            # First digit after the dot must be 1-9 so values < 0.1 (0.0, 0.01) are rejected
            if [[ "$t" =~ ^0?\.[1-9][0-9]*$|^1(\.0+)?$ ]]; then
                # Normalize ".5" style input to "0.5"
                [[ "$t" == .* ]] && t="0$t"
                FUZZY_THRESHOLD=$t
                echo -e "\e[32mSensitivity updated to $FUZZY_THRESHOLD\e[0m"
                sleep 1
            else
                echo -e "\e[31mInvalid value. Must be between 0.1 and 1.0 (e.g. 0.5)\e[0m"
                sleep 2
            fi
            ;;
        *)
            url=$(get_url "$choice_lc")
            if [ -n "$url" ]; then
                echo -e "\e[32mLaunching VLC with selected stream...\e[0m"
                "$VLC" "$url" &
                sleep 1
            else
                echo -e "\e[31mInvalid option. Please try again.\e[0m"
                sleep 1
            fi
            ;;
    esac
done
