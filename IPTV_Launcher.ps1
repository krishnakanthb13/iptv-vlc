# IPTV VLC Launcher - PowerShell Edition
$Host.UI.RawUI.WindowTitle = "IPTV VLC Launcher"

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# --- CONFIGURATION ---
$FuzzyThreshold = 0.7
$ScriptVersion = "0.1.6"
# ---------------------

# Quick search: if a query was passed as argument, skip menu
if ($args.Count -gt 0) {
    $query = $args -join " "
    # Detect VLC
    $vlc = if (Test-Path "C:\Program Files\VideoLAN\VLC\vlc.exe") { "C:\Program Files\VideoLAN\VLC\vlc.exe" }
    elseif (Test-Path "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe") { "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" }
    else { Write-Host "X VLC not found." -ForegroundColor Red; exit 1 }
    # Detect Python properly (bypass MS Store stub)
    $pythonCmd = $null
    foreach ($cmd in "python3", "python") {
        $found = Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue
        if ($found) {
            try { & $found.Source --version 2>$null; $code = $LASTEXITCODE } catch { $code = 1 }
            if ($code -eq 0) { $pythonCmd = $found; break }
        }
    }
    if (-not $pythonCmd) { Write-Host "X Python not found." -ForegroundColor Red; exit 1 }
    $ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $SearchScript = Join-Path $ScriptDir "iptv_search.py"
    if (-not (Test-Path $SearchScript)) { Write-Host "X iptv_search.py not found." -ForegroundColor Red; exit 1 }
    $resultFile = [System.IO.Path]::GetTempFileName()
    $tString = $FuzzyThreshold.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $pyExit = 1
    try {
        & $pythonCmd.Source "$SearchScript" --query "$query" --threshold $tString --output-file "$resultFile"
        $pyExit = $LASTEXITCODE
        if (Test-Path $resultFile) {
            $url = (Get-Content $resultFile -Raw)
            if ($url) { Start-Process -FilePath "$vlc" -ArgumentList "`"$($url.Trim())`"" }
        }
    } finally {
        if (Test-Path $resultFile) { Remove-Item $resultFile -ErrorAction SilentlyContinue }
    }
    # Exit code 2 means "no matches" - treat as benign success
    if ($pyExit -eq 2) { exit 0 }
    if ($pyExit -ne 0) { exit $pyExit }
    exit 0
}

# Detect VLC
$vlc = if (Test-Path "C:\Program Files\VideoLAN\VLC\vlc.exe") { "C:\Program Files\VideoLAN\VLC\vlc.exe" }
elseif (Test-Path "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe") { "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" }
else { 
    Write-Host "X VLC not found. Please install VLC Media Player." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Resolve the directory of this script (works whether run directly or via .bat)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$SearchScript = Join-Path $ScriptDir "iptv_search.py"

# URL Map
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

function Invoke-Search {
    # Detect Python by actually trying to run --version
    # This is the only way to bypass the dummy Microsoft Store aliases reliably
    $pythonCmd = $null
    foreach ($cmd in "python3", "python") {
        $found = Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue
        if ($found) {
            try { & $found.Source --version 2>$null; $code = $LASTEXITCODE } catch { $code = 1 }
            if ($code -eq 0) {
                $pythonCmd = $found
                break
            }
        }
    }

    if (-not $pythonCmd) {
        Write-Host "X Python 3 not found or not functional." -ForegroundColor Red
        Write-Host "  Please install it from https://www.python.org/downloads/" -ForegroundColor Gray
        Write-Host "  Ensure 'Add Python to PATH' is checked during installation." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        return
    }
    if (-not (Test-Path $SearchScript)) {
        Write-Host "X iptv_search.py not found in: $ScriptDir" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Use a temp file so Python can run fully interactively on the console.
    $resultFile = [System.IO.Path]::GetTempFileName()
    $tString = $FuzzyThreshold.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $pyExit = 1
    try {
        # Run Python interactively
        & $pythonCmd.Source "$SearchScript" --threshold $tString --output-file "$resultFile"
        
        $pyExit = $LASTEXITCODE
        if ($pyExit -ne 0 -and $pyExit -ne 2) {
            Write-Host "`n[!] Search engine closed or failed (Exit Code: $pyExit)" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }
        if ($pyExit -eq 2) {
            # No matches found - don't treat as failure
            Start-Sleep -Seconds 2
            return
        }

        if (Test-Path $resultFile) {
            $url = (Get-Content $resultFile -Raw)
            if ($url) {
                $url = $url.Trim()
                Write-Host "`nLaunching VLC..." -ForegroundColor Green
                Start-Process -FilePath "$vlc" -ArgumentList "`"$url`""
                Start-Sleep -Seconds 1
            }
        }
    }
    catch {
        Write-Host "X PowerShell Error: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to return to menu..."
    }
    finally {
        if (Test-Path $resultFile) { Remove-Item $resultFile -ErrorAction SilentlyContinue }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "                     IPTV VLC Launcher v$ScriptVersion" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "VLC: $vlc   Sensitivity: $FuzzyThreshold" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  INDEX / COUNTRIES / REGIONS          CATEGORIES" -ForegroundColor Magenta
    Write-Host "  ------------------------------------ ---------------------------" -ForegroundColor DarkGray

    Write-Host "  1. " -NoNewline -ForegroundColor Yellow; Write-Host " All Channels (Master)            " -NoNewline; Write-Host "14. " -NoNewline -ForegroundColor Yellow; Write-Host "Animation"
    Write-Host "  2. " -NoNewline -ForegroundColor Yellow; Write-Host " Categories (Index)               " -NoNewline; Write-Host "15. " -NoNewline -ForegroundColor Yellow; Write-Host "Comedy"
    Write-Host "  3. " -NoNewline -ForegroundColor Yellow; Write-Host " Languages (Index)                " -NoNewline; Write-Host "16. " -NoNewline -ForegroundColor Yellow; Write-Host "Cooking"
    Write-Host "  4. " -NoNewline -ForegroundColor Yellow; Write-Host " Countries (Index)                " -NoNewline; Write-Host "17. " -NoNewline -ForegroundColor Yellow; Write-Host "Documentary"
    Write-Host "                                       " -NoNewline; Write-Host "18. " -NoNewline -ForegroundColor Yellow; Write-Host "Education"
    Write-Host "  5. " -NoNewline -ForegroundColor Yellow; Write-Host " India                            " -NoNewline; Write-Host "19. " -NoNewline -ForegroundColor Yellow; Write-Host "Entertainment"
    Write-Host "  6. " -NoNewline -ForegroundColor Yellow; Write-Host " United States                    " -NoNewline; Write-Host "20. " -NoNewline -ForegroundColor Yellow; Write-Host "Movies"
    Write-Host "  7. " -NoNewline -ForegroundColor Yellow; Write-Host " Tamil                            " -NoNewline; Write-Host "21. " -NoNewline -ForegroundColor Yellow; Write-Host "News"
    Write-Host "  8. " -NoNewline -ForegroundColor Yellow; Write-Host " Telugu                           " -NoNewline; Write-Host "22. " -NoNewline -ForegroundColor Yellow; Write-Host "Science"
    Write-Host "  9. " -NoNewline -ForegroundColor Yellow; Write-Host " English                          " -NoNewline; Write-Host "23. " -NoNewline -ForegroundColor Yellow; Write-Host "Series"
    Write-Host "                                       " -NoNewline; Write-Host "24. " -NoNewline -ForegroundColor Yellow; Write-Host "Sports"
    Write-Host " 10. " -NoNewline -ForegroundColor Yellow; Write-Host "Americas (All)                    " -NoNewline; Write-Host "25. " -NoNewline -ForegroundColor Yellow; Write-Host "Music"
    Write-Host " 11. " -NoNewline -ForegroundColor Yellow; Write-Host "Central America"
    Write-Host " 12. " -NoNewline -ForegroundColor Yellow; Write-Host "North America"
    Write-Host " 13. " -NoNewline -ForegroundColor Yellow; Write-Host "South America"

    Write-Host ""
    Write-Host "  S. " -NoNewline -ForegroundColor Green; Write-Host " SEARCH CHANNEL              T. " -NoNewline; Write-Host " ADJUST SENSITIVITY" -ForegroundColor Green
    Write-Host "  0. " -NoNewline -ForegroundColor Red; Write-Host " Exit"
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $choice = Read-Host "Select option"
    if ($null -eq $choice) { break }
    $choice = $choice.Trim()

    if ($choice -eq "0") { break }

    # Case-insensitive letter commands
    if ($choice -in @("S", "s")) { Invoke-Search; continue }

    if ($choice -in @("T", "t")) {
        $t = Read-Host "Enter sensitivity (0.1 to 1.0)"
        $parsed = 0.0
        $style = [System.Globalization.NumberStyles]::Any
        $culture = [System.Globalization.CultureInfo]::InvariantCulture
        if ([double]::TryParse($t, $style, $culture, [ref]$parsed) -and $parsed -ge 0.1 -and $parsed -le 1.0) {
            $FuzzyThreshold = $parsed
            Write-Host "Sensitivity updated to $FuzzyThreshold" -ForegroundColor Green
        }
        else {
            Write-Host "Invalid value. Must be between 0.1 and 1.0 (e.g., 0.5)." -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
        continue
    }

    if ($choice -match '^\d+$') {
        $num = [int]$choice
        if ($urls.ContainsKey($num)) {
            $url = $urls[$num]
            Write-Host "`nLaunching VLC with selected stream..." -ForegroundColor Green
            Start-Process -FilePath "$vlc" -ArgumentList "`"$url`""
            Start-Sleep -Seconds 1
            continue
        }
    }

    Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
    Start-Sleep -Seconds 1

} while ($true)

Write-Host "`nGoodbye!" -ForegroundColor Green
# --- END OF SCRIPT ---