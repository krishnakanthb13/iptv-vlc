@echo off
setlocal EnableExtensions EnableDelayedExpansion
title IPTV VLC Launcher
color 0A
set "SCRIPT_VERSION=0.1.12"

:: --------------------------------------------------
:: CONFIGURATION
:: --------------------------------------------------
set "FUZZY_THRESHOLD=0.7"

:: --------------------------------------------------
:: Quick search: if a query was passed as argument, skip menu
:: --------------------------------------------------
if "%~1" NEQ "" (
    goto QUICK_SEARCH
)

:: --------------------------------------------------
:: Detect VLC
:: --------------------------------------------------
set "VLC64=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "VLC32=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"

if exist "%VLC64%" (
    set "VLC=%VLC64%"
) else if exist "%VLC32%" (
    set "VLC=%VLC32%"
) else (
    echo X VLC not found. Please install VLC Media Player.
    pause
    exit /b 1
)

:: --------------------------------------------------
:: INDEX
:: --------------------------------------------------
set IDX1=https://iptv-org.github.io/iptv/index.m3u
set IDX2=https://iptv-org.github.io/iptv/index.category.m3u
set IDX3=https://iptv-org.github.io/iptv/index.language.m3u
set IDX4=https://iptv-org.github.io/iptv/index.country.m3u

:: --------------------------------------------------
:: COUNTRIES / LANGUAGES
:: --------------------------------------------------
set IN=https://iptv-org.github.io/iptv/countries/in.m3u
set US=https://iptv-org.github.io/iptv/countries/us.m3u
set TAM=https://iptv-org.github.io/iptv/languages/tam.m3u
set TEL=https://iptv-org.github.io/iptv/languages/tel.m3u
set ENG=https://iptv-org.github.io/iptv/languages/eng.m3u

:: --------------------------------------------------
:: CATEGORIES
:: --------------------------------------------------
set CAT1=https://iptv-org.github.io/iptv/categories/animation.m3u
set CAT2=https://iptv-org.github.io/iptv/categories/comedy.m3u
set CAT3=https://iptv-org.github.io/iptv/categories/cooking.m3u
set CAT4=https://iptv-org.github.io/iptv/categories/documentary.m3u
set CAT5=https://iptv-org.github.io/iptv/categories/education.m3u
set CAT6=https://iptv-org.github.io/iptv/categories/entertainment.m3u
set CAT7=https://iptv-org.github.io/iptv/categories/movies.m3u
set CAT8=https://iptv-org.github.io/iptv/categories/news.m3u
set CAT9=https://iptv-org.github.io/iptv/categories/science.m3u
set CAT10=https://iptv-org.github.io/iptv/categories/series.m3u
set CAT11=https://iptv-org.github.io/iptv/categories/sports.m3u
set CAT12=https://iptv-org.github.io/iptv/categories/music.m3u

:: --------------------------------------------------
:: REGIONS
:: --------------------------------------------------
set REG1=https://iptv-org.github.io/iptv/regions/amer.m3u
set REG2=https://iptv-org.github.io/iptv/regions/cenamer.m3u
set REG3=https://iptv-org.github.io/iptv/regions/noram.m3u
set REG4=https://iptv-org.github.io/iptv/regions/southam.m3u

:: --------------------------------------------------
:MENU
cls
echo ========================================================================
echo                     IPTV VLC Launcher v%SCRIPT_VERSION%
echo ========================================================================
echo VLC: %VLC%
echo Sensitivity: %FUZZY_THRESHOLD%
echo ------------------------------------------------------------------------
echo.
echo   INDEX / COUNTRIES / REGIONS          CATEGORIES
echo   ------------------------------------ ---------------------------
echo   1.  All Channels (Master)            14. Animation
echo   2.  Categories (Index)               15. Comedy
echo   3.  Languages (Index)                16. Cooking
echo   4.  Countries (Index)                17. Documentary
echo                                        18. Education
echo   5.  India                            19. Entertainment
echo   6.  United States                    20. Movies
echo   7.  Tamil                            21. News
echo   8.  Telugu                           22. Science
echo   9.  English                          23. Series
echo                                        24. Sports
echo  10. Americas (All)                    25. Music
echo  11. Central America
echo  12. North America
echo  13. South America
echo.
echo   S.  SEARCH CHANNEL                   T.  ADJUST SENSITIVITY
echo   H.  HELP / ABOUT                      0.  Exit
echo.
echo ========================================================================
set "opt="
set /p opt=Select option: 
if not defined opt goto MENU

if /i "%opt%"=="S" goto SEARCH
if /i "%opt%"=="T" goto SENSITIVITY
if /i "%opt%"=="H" goto HELP
if "%opt%"=="0" exit /b 0

:: Each branch is parenthesized: without the parentheses,
:: "& goto MENU" would run unconditionally because CMD
:: treats "&" as a command separator outside the if.
if "%opt%"=="1" (
    start "" "%VLC%" "%IDX1%"
    goto MENU
)
if "%opt%"=="2" (
    start "" "%VLC%" "%IDX2%"
    goto MENU
)
if "%opt%"=="3" (
    start "" "%VLC%" "%IDX3%"
    goto MENU
)
if "%opt%"=="4" (
    start "" "%VLC%" "%IDX4%"
    goto MENU
)

if "%opt%"=="5" (
    start "" "%VLC%" "%IN%"
    goto MENU
)
if "%opt%"=="6" (
    start "" "%VLC%" "%US%"
    goto MENU
)
if "%opt%"=="7" (
    start "" "%VLC%" "%TAM%"
    goto MENU
)
if "%opt%"=="8" (
    start "" "%VLC%" "%TEL%"
    goto MENU
)
if "%opt%"=="9" (
    start "" "%VLC%" "%ENG%"
    goto MENU
)

if "%opt%"=="10" (
    start "" "%VLC%" "%REG1%"
    goto MENU
)
if "%opt%"=="11" (
    start "" "%VLC%" "%REG2%"
    goto MENU
)
if "%opt%"=="12" (
    start "" "%VLC%" "%REG3%"
    goto MENU
)
if "%opt%"=="13" (
    start "" "%VLC%" "%REG4%"
    goto MENU
)

if "%opt%"=="14" (
    start "" "%VLC%" "%CAT1%"
    goto MENU
)
if "%opt%"=="15" (
    start "" "%VLC%" "%CAT2%"
    goto MENU
)
if "%opt%"=="16" (
    start "" "%VLC%" "%CAT3%"
    goto MENU
)
if "%opt%"=="17" (
    start "" "%VLC%" "%CAT4%"
    goto MENU
)
if "%opt%"=="18" (
    start "" "%VLC%" "%CAT5%"
    goto MENU
)
if "%opt%"=="19" (
    start "" "%VLC%" "%CAT6%"
    goto MENU
)
if "%opt%"=="20" (
    start "" "%VLC%" "%CAT7%"
    goto MENU
)
if "%opt%"=="21" (
    start "" "%VLC%" "%CAT8%"
    goto MENU
)
if "%opt%"=="22" (
    start "" "%VLC%" "%CAT9%"
    goto MENU
)
if "%opt%"=="23" (
    start "" "%VLC%" "%CAT10%"
    goto MENU
)
if "%opt%"=="24" (
    start "" "%VLC%" "%CAT11%"
    goto MENU
)
if "%opt%"=="25" (
    start "" "%VLC%" "%CAT12%"
    goto MENU
)

echo Invalid option. Please try again.
timeout /t 2 >nul
goto MENU

:: --------------------------------------------------
:QUICK_SEARCH
:: Ensure VLC is detected (may be reached before main VLC detection)
if not defined VLC (
    if exist "C:\Program Files\VideoLAN\VLC\vlc.exe" (
        set "VLC=C:\Program Files\VideoLAN\VLC\vlc.exe"
    ) else if exist "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" (
        set "VLC=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
    )
)
if not defined VLC (
    echo X VLC not found.
    exit /b 1
)

:: Pick the first Python candidate that actually runs and is Python 3.
:: "where" alone is not enough: the Microsoft Store
:: installs python3.exe/python.exe aliases that exist
:: on disk but fail with exit 9009. We verify --version
:: exits cleanly and confirms major version >= 3.
set "PY_CMD="
for %%C in (python3 python) do (
    if not defined PY_CMD (
        where %%C >nul 2>nul
        if !errorlevel! equ 0 (
            %%C --version >nul 2>nul
            if !errorlevel! equ 0 (
                for /f "tokens=2 delims= " %%V in ('%%C --version 2^>^&1') do (
                    for /f "tokens=1 delims=." %%M in ("%%V") do (
                        if %%M geq 3 set "PY_CMD=%%C"
                    )
                )
            )
        )
    )
)
if not defined PY_CMD (
    echo X Python not found. Please install Python 3 to use search.
    pause
    exit /b 1
)

if not exist "%~dp0iptv_search.py" (
    echo X iptv_search.py not found.
    pause
    exit /b 1
)

call :GEN_RESULT_FILE

:: Run with delayed expansion off so a "!" in the
:: query survives CMD parsing intact - with
:: EnableDelayedExpansion on, a "!" in %* would
:: consume a span of the line and corrupt the
:: arguments Python receives.
setlocal DisableDelayedExpansion
%PY_CMD% "%~dp0iptv_search.py" --query %* --threshold %FUZZY_THRESHOLD% --output-file "%RESULT_FILE%"
set "TMP_EXIT=%errorlevel%"
endlocal & set "PY_EXIT=%TMP_EXIT%"

if exist "%RESULT_FILE%" (
    set /p RESULT_URL=<"%RESULT_FILE%"
    del "%RESULT_FILE%"
) else (
    set "RESULT_URL="
)

if !PY_EXIT! equ 0 (
    if defined RESULT_URL (
        start "" "%VLC%" "%RESULT_URL%"
        exit /b 0
    ) else (
        echo X No channel URL was produced.
        exit /b 1
    )
)
:: Exit codes 2 (no matches) and 3 (no selection) are
:: benign outcomes for a CLI invocation - report success.
if !PY_EXIT! equ 2 exit /b 0
if !PY_EXIT! equ 3 exit /b 0
exit /b !PY_EXIT!

:: --------------------------------------------------
:SEARCH
:: Pick the first Python candidate that actually runs and is Python 3.
:: "where" alone is not enough: the Microsoft Store
:: installs python3.exe/python.exe aliases that exist
:: on disk but fail with exit 9009. We verify --version
:: exits cleanly and confirms major version >= 3.
set "PY_CMD="
for %%C in (python3 python) do (
    if not defined PY_CMD (
        where %%C >nul 2>nul
        if !errorlevel! equ 0 (
            %%C --version >nul 2>nul
            if !errorlevel! equ 0 (
                for /f "tokens=2 delims= " %%V in ('%%C --version 2^>^&1') do (
                    for /f "tokens=1 delims=." %%M in ("%%V") do (
                        if %%M geq 3 set "PY_CMD=%%C"
                    )
                )
            )
        )
    )
)
if not defined PY_CMD (
    echo X Python not found. Please install Python 3 to use search.
    pause
    goto MENU
)

if not exist "%~dp0iptv_search.py" (
    echo X iptv_search.py not found.
    pause
    goto MENU
)

call :GEN_RESULT_FILE

:: Run the Python search engine interactively
%PY_CMD% "%~dp0iptv_search.py" --threshold %FUZZY_THRESHOLD% --output-file "%RESULT_FILE%"
set "PY_EXIT=%errorlevel%"

if exist "%RESULT_FILE%" (
    set /p RESULT_URL=<"%RESULT_FILE%"
    del "%RESULT_FILE%"
) else (
    set "RESULT_URL="
)

if "!PY_EXIT!" equ "0" (
    if defined RESULT_URL (
        echo.
        echo Launching VLC with selected stream...
        start "" "%VLC%" "%RESULT_URL%"
    ) else (
        echo.
        echo No channel was selected.
        timeout /t 2 >nul
    )
) else if "!PY_EXIT!" equ "2" (
    echo.
    echo No channels matched your search.
    timeout /t 2 >nul
) else if "!PY_EXIT!" equ "3" (
    echo.
    echo No channel was selected.
    timeout /t 2 >nul
) else (
    echo.
    echo X Search engine failed, exit code !PY_EXIT!.
    timeout /t 3 >nul
)
goto MENU

:: --------------------------------------------------
:SENSITIVITY
set "new_t="
set /p new_t=Enter new sensitivity (0.1 - 1.0): 
if not defined new_t goto MENU
:: Validate without echoing raw input into a command.
:: First: allow only digits and dot by stripping them all;
:: anything left means a disallowed (possibly dangerous)
:: character was entered. Each strip is guarded because
:: substituting on an empty variable is a cmd quirk.
set "check=!new_t!"
if defined check set "check=!check:0=!"
if defined check set "check=!check:1=!"
if defined check set "check=!check:2=!"
if defined check set "check=!check:3=!"
if defined check set "check=!check:4=!"
if defined check set "check=!check:5=!"
if defined check set "check=!check:6=!"
if defined check set "check=!check:7=!"
if defined check set "check=!check:8=!"
if defined check set "check=!check:9=!"
if defined check set "check=!check:.=!"
if defined check (
    echo Invalid value. Must be between 0.1 and 1.0 - e.g. 0.5, 0.75, 1.0
    timeout /t 2 >nul
    goto MENU
)
:: Second: range/format check. Input is now known to contain
:: only [0-9.], so findstr cannot be fed metacharacters.
echo !new_t!| findstr /r "^0\.[1-9][0-9]*$ ^1\.[0][0]*$ ^1$ ^\.[1-9][0-9]*$" >nul 2>nul
if errorlevel 1 (
    echo Invalid value. Must be between 0.1 and 1.0 - e.g. 0.5, 0.75, 1.0
    timeout /t 2 >nul
    goto MENU
)
:: Normalize ".5" style input to "0.5"
if "!new_t:~0,1!"=="." set "new_t=0!new_t!"
set "FUZZY_THRESHOLD=%new_t%"
echo Sensitivity updated to %FUZZY_THRESHOLD%
timeout /t 1 >nul
goto MENU

:: --------------------------------------------------
:HELP
cls
echo ========================================================================
echo                     IPTV VLC Launcher v%SCRIPT_VERSION%
echo ========================================================================
echo.
echo USAGE:
echo   IPTV_Launcher.bat                   Open interactive menu
echo   IPTV_Launcher.bat "channel name"    Quick search and launch
echo.
echo MENU OPTIONS:
echo   1-25  Select a channel list to open in VLC
echo   S     Fuzzy search across all 30,000+ channels
echo   T     Adjust search sensitivity (0.1 loose - 1.0 exact)
echo   H     Show this help screen
echo   0     Exit
echo.
echo QUICK SEARCH EXAMPLES:
echo   IPTV_Launcher.bat "BBC News"
echo   IPTV_Launcher.bat "ESPN"
echo   IPTV_Launcher.bat "Discovery"
echo.
echo REQUIREMENTS:
echo   - Python 3.6+ (https://www.python.org/downloads/)
echo   - VLC Media Player (https://www.videolan.org/)
echo.
echo ========================================================================
echo.
pause
goto MENU

:: --------------------------------------------------
:: SUBROUTINES
:: --------------------------------------------------
:: Generates a unique result-file name in RESULT_FILE.
:: Two RANDOM values give ~1 billion combinations, and an
:: existing name is never reused or deleted - a pre-existing
:: file may belong to another running launcher instance.
:GEN_RESULT_FILE
set "RESULT_FILE=%TEMP%\iptv_result_%RANDOM%_%RANDOM%.txt"
if exist "%RESULT_FILE%" goto GEN_RESULT_FILE
goto :eof