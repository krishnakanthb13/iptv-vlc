# IPTV VLC Launcher - PowerShell Edition
$Host.UI.RawUI.WindowTitle = "IPTV VLC Launcher"

# Detect VLC (prefer 64-bit)
$vlc64 = "C:\Program Files\VideoLAN\VLC\vlc.exe"
$vlc32 = "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"

if (Test-Path $vlc64) {
    $vlc = $vlc64
} elseif (Test-Path $vlc32) {
    $vlc = $vlc32
} else {
    Write-Host "X VLC not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# INDEX URLs
$urls = @{
    1  = "https://iptv-org.github.io/iptv/index.m3u"
    2  = "https://iptv-org.github.io/iptv/index.category.m3u"
    3  = "https://iptv-org.github.io/iptv/index.language.m3u"
    4  = "https://iptv-org.github.io/iptv/index.country.m3u"
    
    # Countries/Languages
    5  = "https://iptv-org.github.io/iptv/countries/in.m3u"
    6  = "https://iptv-org.github.io/iptv/countries/us.m3u"
    7  = "https://iptv-org.github.io/iptv/languages/tam.m3u"
    8  = "https://iptv-org.github.io/iptv/languages/tel.m3u"
    9  = "https://iptv-org.github.io/iptv/languages/eng.m3u"
    
    # Regions
    10 = "https://iptv-org.github.io/iptv/regions/amer.m3u"
    11 = "https://iptv-org.github.io/iptv/regions/cenamer.m3u"
    12 = "https://iptv-org.github.io/iptv/regions/noram.m3u"
    13 = "https://iptv-org.github.io/iptv/regions/southam.m3u"
    
    # Categories
    14 = "https://iptv-org.github.io/iptv/categories/animation.m3u"
    15 = "https://iptv-org.github.io/iptv/categories/comedy.m3u"
    16 = "https://iptv-org.github.io/iptv/categories/cooking.m3u"
    17 = "https://iptv-org.github.io/iptv/categories/documentary.m3u"
    18 = "https://iptv-org.github.io/iptv/categories/education.m3u"
    19 = "https://iptv-org.github.io/iptv/categories/entertainment.m3u"
    20 = "https://iptv-org.github.io/iptv/categories/movies.m3u"
    21 = "https://iptv-org.github.io/iptv/categories/news.m3u"
    22 = "https://iptv-org.github.io/iptv/categories/science.m3u"
    23 = "https://iptv-org.github.io/iptv/categories/series.m3u"
    24 = "https://iptv-org.github.io/iptv/categories/sports.m3u"
    25 = "https://iptv-org.github.io/iptv/categories/music.m3u"
}

function Show-Menu {
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "                          IPTV VLC Launcher                             " -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "VLC: " -NoNewline -ForegroundColor Yellow
    Write-Host $vlc -ForegroundColor White
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  INDEX / COUNTRIES / REGIONS          CATEGORIES" -ForegroundColor Magenta
    Write-Host "  ------------------------------------ ---------------------------" -ForegroundColor DarkGray
    
    Write-Host "  1. " -NoNewline -ForegroundColor Yellow
    Write-Host " All Channels (Master)            " -NoNewline -ForegroundColor White
    Write-Host "14. " -NoNewline -ForegroundColor Yellow
    Write-Host "Animation" -ForegroundColor White
    
    Write-Host "  2. " -NoNewline -ForegroundColor Yellow
    Write-Host " Categories (Index)               " -NoNewline -ForegroundColor White
    Write-Host "15. " -NoNewline -ForegroundColor Yellow
    Write-Host "Comedy" -ForegroundColor White
    
    Write-Host "  3. " -NoNewline -ForegroundColor Yellow
    Write-Host " Languages (Index)                " -NoNewline -ForegroundColor White
    Write-Host "16. " -NoNewline -ForegroundColor Yellow
    Write-Host "Cooking" -ForegroundColor White
    
    Write-Host "  4. " -NoNewline -ForegroundColor Yellow
    Write-Host " Countries (Index)                " -NoNewline -ForegroundColor White
    Write-Host "17. " -NoNewline -ForegroundColor Yellow
    Write-Host "Documentary" -ForegroundColor White
    
    Write-Host "                                       " -NoNewline
    Write-Host "18. " -NoNewline -ForegroundColor Yellow
    Write-Host "Education" -ForegroundColor White
    
    Write-Host "  5. " -NoNewline -ForegroundColor Yellow
    Write-Host " India                            " -NoNewline -ForegroundColor White
    Write-Host "19. " -NoNewline -ForegroundColor Yellow
    Write-Host "Entertainment" -ForegroundColor White
    
    Write-Host "  6. " -NoNewline -ForegroundColor Yellow
    Write-Host " United States                    " -NoNewline -ForegroundColor White
    Write-Host "20. " -NoNewline -ForegroundColor Yellow
    Write-Host "Movies" -ForegroundColor White
    
    Write-Host "  7. " -NoNewline -ForegroundColor Yellow
    Write-Host " Tamil                            " -NoNewline -ForegroundColor White
    Write-Host "21. " -NoNewline -ForegroundColor Yellow
    Write-Host "News" -ForegroundColor White
    
    Write-Host "  8. " -NoNewline -ForegroundColor Yellow
    Write-Host " Telugu                           " -NoNewline -ForegroundColor White
    Write-Host "22. " -NoNewline -ForegroundColor Yellow
    Write-Host "Science" -ForegroundColor White
    
    Write-Host "  9. " -NoNewline -ForegroundColor Yellow
    Write-Host " English                          " -NoNewline -ForegroundColor White
    Write-Host "23. " -NoNewline -ForegroundColor Yellow
    Write-Host "Series" -ForegroundColor White
    
    Write-Host "                                       " -NoNewline
    Write-Host "24. " -NoNewline -ForegroundColor Yellow
    Write-Host "Sports" -ForegroundColor White
    
    Write-Host " 10. " -NoNewline -ForegroundColor Yellow
    Write-Host "Americas (All)                    " -NoNewline -ForegroundColor White
    Write-Host "25. " -NoNewline -ForegroundColor Yellow
    Write-Host "Music" -ForegroundColor White
    
    Write-Host " 11. " -NoNewline -ForegroundColor Yellow
    Write-Host "Central America" -ForegroundColor White
    
    Write-Host " 12. " -NoNewline -ForegroundColor Yellow
    Write-Host "North America" -ForegroundColor White
    
    Write-Host " 13. " -NoNewline -ForegroundColor Yellow
    Write-Host "South America" -ForegroundColor White
    
    Write-Host ""
    Write-Host "  0. " -NoNewline -ForegroundColor Red
    Write-Host " Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option"
    
    if ($choice -eq "0") {
        break
    }
    
    if ($urls.ContainsKey([int]$choice)) {
        $url = $urls[[int]$choice]
        Write-Host "`nLaunching VLC with selected stream..." -ForegroundColor Green
        Start-Process -FilePath $vlc -ArgumentList $url
        Start-Sleep -Seconds 1
    } else {
        Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
    
} while ($true)

Write-Host "`nGoodbye!" -ForegroundColor Green