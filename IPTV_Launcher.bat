@echo off
setlocal EnableExtensions EnableDelayedExpansion
title IPTV VLC Launcher
color 0A

:: --------------------------------------------------
:: CONFIGURATION
:: --------------------------------------------------
set "FUZZY_THRESHOLD=0.7"

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
echo                          IPTV VLC Launcher
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
echo   0.  Exit
echo.
echo ========================================================================
set "opt="
set /p opt=Select option: 
if not defined opt goto MENU

if /i "%opt%"=="S" goto SEARCH
if /i "%opt%"=="T" goto SENSITIVITY
if "%opt%"=="0" exit /b 0

if "%opt%"=="1"  start "" "%VLC%" "%IDX1%" & goto MENU
if "%opt%"=="2"  start "" "%VLC%" "%IDX2%" & goto MENU
if "%opt%"=="3"  start "" "%VLC%" "%IDX3%" & goto MENU
if "%opt%"=="4"  start "" "%VLC%" "%IDX4%" & goto MENU

if "%opt%"=="5"  start "" "%VLC%" "%IN%"   & goto MENU
if "%opt%"=="6"  start "" "%VLC%" "%US%"   & goto MENU
if "%opt%"=="7"  start "" "%VLC%" "%TAM%"  & goto MENU
if "%opt%"=="8"  start "" "%VLC%" "%TEL%"  & goto MENU
if "%opt%"=="9"  start "" "%VLC%" "%ENG%"  & goto MENU

if "%opt%"=="10" start "" "%VLC%" "%REG1%" & goto MENU
if "%opt%"=="11" start "" "%VLC%" "%REG2%" & goto MENU
if "%opt%"=="12" start "" "%VLC%" "%REG3%" & goto MENU
if "%opt%"=="13" start "" "%VLC%" "%REG4%" & goto MENU

if "%opt%"=="14" start "" "%VLC%" "%CAT1%"  & goto MENU
if "%opt%"=="15" start "" "%VLC%" "%CAT2%"  & goto MENU
if "%opt%"=="16" start "" "%VLC%" "%CAT3%"  & goto MENU
if "%opt%"=="17" start "" "%VLC%" "%CAT4%"  & goto MENU
if "%opt%"=="18" start "" "%VLC%" "%CAT5%"  & goto MENU
if "%opt%"=="19" start "" "%VLC%" "%CAT6%"  & goto MENU
if "%opt%"=="20" start "" "%VLC%" "%CAT7%"  & goto MENU
if "%opt%"=="21" start "" "%VLC%" "%CAT8%"  & goto MENU
if "%opt%"=="22" start "" "%VLC%" "%CAT9%"  & goto MENU
if "%opt%"=="23" start "" "%VLC%" "%CAT10%" & goto MENU
if "%opt%"=="24" start "" "%VLC%" "%CAT11%" & goto MENU
if "%opt%"=="25" start "" "%VLC%" "%CAT12%" & goto MENU

echo Invalid option. Please try again.
timeout /t 2 >nul
goto MENU

:: --------------------------------------------------
:SEARCH
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo X Python not found. Please install Python 3 to use search.
    pause
    goto MENU
)

set "RESULT_FILE=%TEMP%\iptv_result_%RANDOM%.txt"
if exist "%RESULT_FILE%" del "%RESULT_FILE%"

:: Run the Python search engine interactively
python "%~dp0iptv_search.py" --threshold %FUZZY_THRESHOLD% --output-file "%RESULT_FILE%"

if exist "%RESULT_FILE%" (
    set /p RESULT_URL=<"%RESULT_FILE%"
    del "%RESULT_FILE%"
) else (
    set "RESULT_URL="
)

if defined RESULT_URL (
    echo.
    echo Launching VLC with selected stream...
    start "" "%VLC%" "%RESULT_URL%"
) else (
    echo.
    echo No channel was selected.
    timeout /t 2 >nul
)
goto MENU

:: --------------------------------------------------
:SENSITIVITY
set "new_t="
set /p new_t=Enter new sensitivity (0.1 - 1.0): 
if not defined new_t goto MENU
:: Basic check: must contain a dot
echo %new_t% | findstr /r "\." >nul 2>nul
if errorlevel 1 (
    echo Invalid value. Must be a decimal like 0.5
    timeout /t 2 >nul
    goto MENU
)
set "FUZZY_THRESHOLD=%new_t%"
echo Sensitivity updated to %FUZZY_THRESHOLD%
timeout /t 1 >nul
goto MENU