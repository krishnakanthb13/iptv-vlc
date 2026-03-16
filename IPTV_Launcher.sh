#!/bin/bash

# IPTV VLC Launcher - Bash Edition

# Detect VLC
if command -v vlc &>/dev/null; then
    VLC="vlc"
elif [ -f "/usr/bin/vlc" ]; then
    VLC="/usr/bin/vlc"
elif [ -f "/Applications/VLC.app/Contents/MacOS/VLC" ]; then
    VLC="/Applications/VLC.app/Contents/MacOS/VLC"
else
    echo "X VLC not found."
    read -r -p "Press Enter to exit..."
    exit 1
fi

# URL Map (indexed by number)
declare -A URLS
# INDEX
URLS[1]="https://iptv-org.github.io/iptv/index.m3u"
URLS[2]="https://iptv-org.github.io/iptv/index.category.m3u"
URLS[3]="https://iptv-org.github.io/iptv/index.language.m3u"
URLS[4]="https://iptv-org.github.io/iptv/index.country.m3u"

# Countries / Languages
URLS[5]="https://iptv-org.github.io/iptv/countries/in.m3u"
URLS[6]="https://iptv-org.github.io/iptv/countries/us.m3u"
URLS[7]="https://iptv-org.github.io/iptv/languages/tam.m3u"
URLS[8]="https://iptv-org.github.io/iptv/languages/tel.m3u"
URLS[9]="https://iptv-org.github.io/iptv/languages/eng.m3u"

# Regions
URLS[10]="https://iptv-org.github.io/iptv/regions/amer.m3u"
URLS[11]="https://iptv-org.github.io/iptv/regions/cenamer.m3u"
URLS[12]="https://iptv-org.github.io/iptv/regions/noram.m3u"
URLS[13]="https://iptv-org.github.io/iptv/regions/southam.m3u"

# Categories
URLS[14]="https://iptv-org.github.io/iptv/categories/animation.m3u"
URLS[15]="https://iptv-org.github.io/iptv/categories/comedy.m3u"
URLS[16]="https://iptv-org.github.io/iptv/categories/cooking.m3u"
URLS[17]="https://iptv-org.github.io/iptv/categories/documentary.m3u"
URLS[18]="https://iptv-org.github.io/iptv/categories/education.m3u"
URLS[19]="https://iptv-org.github.io/iptv/categories/entertainment.m3u"
URLS[20]="https://iptv-org.github.io/iptv/categories/movies.m3u"
URLS[21]="https://iptv-org.github.io/iptv/categories/news.m3u"
URLS[22]="https://iptv-org.github.io/iptv/categories/science.m3u"
URLS[23]="https://iptv-org.github.io/iptv/categories/series.m3u"
URLS[24]="https://iptv-org.github.io/iptv/categories/sports.m3u"
URLS[25]="https://iptv-org.github.io/iptv/categories/music.m3u"

show_menu() {
    clear
    echo -e "\e[36m========================================================================\e[0m"
    echo -e "\e[32m                         IPTV VLC Launcher                             \e[0m"
    echo -e "\e[36m========================================================================\e[0m"
    echo -e "\e[33mVLC:\e[0m $VLC"
    echo -e "\e[36m------------------------------------------------------------------------\e[0m"
    echo ""
    echo -e "\e[35m  INDEX / COUNTRIES / REGIONS          CATEGORIES\e[0m"
    echo -e "\e[90m  ------------------------------------ ---------------------------\e[0m"
    echo -e "\e[33m  1.\e[0m  All Channels (Master)            \e[33m14.\e[0m Animation"
    echo -e "\e[33m  2.\e[0m  Categories (Index)               \e[33m15.\e[0m Comedy"
    echo -e "\e[33m  3.\e[0m  Languages (Index)                \e[33m16.\e[0m Cooking"
    echo -e "\e[33m  4.\e[0m  Countries (Index)                \e[33m17.\e[0m Documentary"
    echo -e "                                       \e[33m18.\e[0m Education"
    echo -e "\e[33m  5.\e[0m  India                            \e[33m19.\e[0m Entertainment"
    echo -e "\e[33m  6.\e[0m  United States                    \e[33m20.\e[0m Movies"
    echo -e "\e[33m  7.\e[0m  Tamil                            \e[33m21.\e[0m News"
    echo -e "\e[33m  8.\e[0m  Telugu                           \e[33m22.\e[0m Science"
    echo -e "\e[33m  9.\e[0m  English                          \e[33m23.\e[0m Series"
    echo -e "                                       \e[33m24.\e[0m Sports"
    echo -e "\e[33m 10.\e[0m Americas (All)                    \e[33m25.\e[0m Music"
    echo -e "\e[33m 11.\e[0m Central America"
    echo -e "\e[33m 12.\e[0m North America"
    echo -e "\e[33m 13.\e[0m South America"
    echo ""
    echo -e "\e[31m  0.\e[0m  Exit"
    echo ""
    echo -e "\e[36m========================================================================\e[0m"
}

# Main loop
while true; do
    show_menu
    read -r -p "Select option: " choice

    if [ "$choice" = "0" ]; then
        break
    fi

    if [[ -n "${URLS[$choice]}" ]]; then
        echo -e "\n\e[32mLaunching VLC with selected stream...\e[0m"
        "$VLC" "${URLS[$choice]}" &
        sleep 1
    else
        echo -e "\n\e[31mInvalid option. Please try again.\e[0m"
        sleep 2
    fi
done

echo -e "\n\e[32mGoodbye!\e[0m"
