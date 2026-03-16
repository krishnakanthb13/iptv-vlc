@echo off
setlocal EnableExtensions EnableDelayedExpansion
title IPTV VLC Launcher
color 0A

:: --------------------------------------------------
:: Detect VLC (prefer 64-bit)
:: --------------------------------------------------
set "VLC64=C:\Program Files\VideoLAN\VLC\vlc.exe"
set "VLC32=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"

if exist "%VLC64%" (
    set "VLC=%VLC64%"
) else if exist "%VLC32%" (
    set "VLC=%VLC32%"
) else (
    echo X VLC not found.
    pause
    exit /b
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
set REG4=https://iptv-org.github.io/iptv/regions/nam.m3u
set REG5=https://iptv-org.github.io/iptv/regions/southam.m3u

:: --------------------------------------------------
:MENU
cls
echo ========================================================================
echo                          IPTV VLC Launcher
echo ========================================================================
echo VLC: %VLC%
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
echo   0.  Exit
echo.
echo ========================================================================
set /p opt=Select option: 

if "%opt%"=="1"  "%VLC%" "%IDX1%" & goto MENU
if "%opt%"=="2"  "%VLC%" "%IDX2%" & goto MENU
if "%opt%"=="3"  "%VLC%" "%IDX3%" & goto MENU
if "%opt%"=="4"  "%VLC%" "%IDX4%" & goto MENU

if "%opt%"=="5"  "%VLC%" "%IN%"  & goto MENU
if "%opt%"=="6"  "%VLC%" "%US%"  & goto MENU
if "%opt%"=="7"  "%VLC%" "%TAM%" & goto MENU
if "%opt%"=="8"  "%VLC%" "%TEL%" & goto MENU
if "%opt%"=="9"  "%VLC%" "%ENG%" & goto MENU

if "%opt%"=="10" "%VLC%" "%REG1%" & goto MENU
if "%opt%"=="11" "%VLC%" "%REG2%" & goto MENU
if "%opt%"=="12" "%VLC%" "%REG3%" & goto MENU
if "%opt%"=="13" "%VLC%" "%REG5%" & goto MENU

if "%opt%"=="14" "%VLC%" "%CAT1%"  & goto MENU
if "%opt%"=="15" "%VLC%" "%CAT2%"  & goto MENU
if "%opt%"=="16" "%VLC%" "%CAT3%"  & goto MENU
if "%opt%"=="17" "%VLC%" "%CAT4%"  & goto MENU
if "%opt%"=="18" "%VLC%" "%CAT5%"  & goto MENU
if "%opt%"=="19" "%VLC%" "%CAT6%"  & goto MENU
if "%opt%"=="20" "%VLC%" "%CAT7%"  & goto MENU
if "%opt%"=="21" "%VLC%" "%CAT8%"  & goto MENU
if "%opt%"=="22" "%VLC%" "%CAT9%"  & goto MENU
if "%opt%"=="23" "%VLC%" "%CAT10%" & goto MENU
if "%opt%"=="24" "%VLC%" "%CAT11%" & goto MENU
if "%opt%"=="25" "%VLC%" "%CAT12%" & goto MENU

if "%opt%"=="0" exit /b

echo Invalid option.
pause
goto MENU