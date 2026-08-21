@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Portable Video Encoder

:: ============================================================
::                  PORTABLE VIDEO ENCODER
:: ============================================================

set "BASE=%~dp0"
set "FFMPEG=%BASE%ffmpeg.exe"
set "INPUT=%BASE%Input"
set "OUTPUT=%BASE%Output"

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

cls

echo ============================================================
echo                  PORTABLE VIDEO ENCODER
echo ============================================================
echo.
echo FFmpeg:
echo %FFMPEG%
echo.
echo Input:
echo %INPUT%
echo.
echo Output:
echo %OUTPUT%
echo.
echo ============================================================
echo.

:: ============================================================
:: CHECK FFMPEG
:: ============================================================

echo Checking FFmpeg...
echo.

if not exist "%FFMPEG%" (
    echo [ERROR] ffmpeg.exe was not found!
    echo.
    echo Please place ffmpeg.exe in:
    echo %BASE%
    echo.
    goto ERROR_EXIT
)

"%FFMPEG%" -version >nul 2>&1

if errorlevel 1 (
    echo [ERROR] FFmpeg could not be started.
    echo.
    goto ERROR_EXIT
)

for /f "tokens=1,*" %%A in ('"%FFMPEG%" -version 2^>nul') do (
    echo [OK] %%A %%B
    goto FFMPEG_VERSION_DONE
)

:FFMPEG_VERSION_DONE

echo.

:: ============================================================
:: CHECK SVT-AV1
:: ============================================================

echo Checking SVT-AV1 encoder...
echo.

"%FFMPEG%" -hide_banner -encoders 2>nul | findstr /i "libsvtav1" >nul

if errorlevel 1 (
    echo [ERROR] SVT-AV1 encoder was not found.
    echo.
    echo Your FFmpeg build must include:
    echo libsvtav1
    echo.
    goto ERROR_EXIT
)

echo [OK] SVT-AV1 encoder found.
echo.

:: ============================================================
:: FIND VIDEOS
:: ============================================================

set /a COUNT=0

echo Videos found:
echo.

for %%F in ("%INPUT%\*.mp4") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

for %%F in ("%INPUT%\*.mov") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

for %%F in ("%INPUT%\*.mkv") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

for %%F in ("%INPUT%\*.avi") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

for %%F in ("%INPUT%\*.webm") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

for %%F in ("%INPUT%\*.m4v") do (
    if exist "%%~fF" (
        set /a COUNT+=1
        set "FILE!COUNT!=%%~fF"
        set "NAME!COUNT!=%%~nxF"
    )
)

if %COUNT% EQU 0 (
    echo No supported video files were found.
    echo.
    echo Put videos inside:
    echo %INPUT%
    echo.
    goto NORMAL_EXIT
)

for /L %%N in (1,1,%COUNT%) do (
    echo %%N. !NAME%%N!
)

echo.
echo Total videos: %COUNT%
echo.

:: ============================================================
:: ENCODING SETTINGS
:: ============================================================

echo ============================================================
echo                     ENCODING SETTINGS
echo ============================================================
echo.
echo Codec:        AV1 (SVT-AV1)
echo Audio:        Opus
echo Pixel format: 10-bit
echo.
echo CRF controls quality:
echo.
echo   20 = Very high quality / larger files
echo   25 = High quality
echo   30 = Good quality
echo   35 = Smaller files
echo   40 = Very small files
echo.

set "CRF="
set /p "CRF=Enter CRF (default 30): "

if not defined CRF set "CRF=30"

echo.
echo.

:: ============================================================
:: PRESET
:: ============================================================

echo SVT-AV1 preset:
echo.
echo   1  = Slowest / best compression
echo   2  = Very slow
echo   3  = Slow
echo   4  = Balanced
echo   5  = Faster
echo   6  = Fast
echo   7  = Very fast
echo   8  = Extremely fast
echo   10 = Fastest
echo.

set "PRESET="
set /p "PRESET=Enter preset (default 4): "

if not defined PRESET set "PRESET=4"

echo.
echo.

:: ============================================================
:: AUDIO BITRATE
:: ============================================================

echo Audio bitrate:
echo.
echo   64k  = Small
echo   96k  = Good
echo   128k = Recommended
echo   160k = High
echo   192k = Very high
echo.

set "AUDIO="
set /p "AUDIO=Enter audio bitrate (default 128k): "

if not defined AUDIO set "AUDIO=128k"

echo.
echo.

:: ============================================================
:: AUDIO CHANNELS
:: ============================================================

echo Audio channels:
echo.
echo   1 = 2.0 Stereo
echo   2 = 5.1 Surround
echo.

set "CHANNELS="
set /p "CHANNELS=Choose audio channels (default 1): "

if not defined CHANNELS set "CHANNELS=1"

if "%CHANNELS%"=="1" (
    set "AC=2"
    set "CHANNAME=2.0 Stereo"
)

if "%CHANNELS%"=="2" (
    set "AC=6"
    set "CHANNAME=5.1 Surround"
)

if not defined CHANNAME (
    echo.
    echo [ERROR] Invalid audio channel selection.
    echo.
    goto ERROR_EXIT
)

echo.
echo.

:: ============================================================
:: RESOLUTION
:: ============================================================

echo Resolution:
echo.
echo   1 = Original resolution
echo   2 = 1080p
echo   3 = 720p
echo   4 = 540p
echo   5 = 480p
echo.

set "RESOLUTION="
set /p "RESOLUTION=Choose resolution (default 1): "

if not defined RESOLUTION set "RESOLUTION=1"

if "%RESOLUTION%"=="1" (
    set "SCALE="
    set "RESNAME=Original"
)

if "%RESOLUTION%"=="2" (
    set "SCALE=-vf scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"
    set "RESNAME=1080p"
)

if "%RESOLUTION%"=="3" (
    set "SCALE=-vf scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"
    set "RESNAME=720p"
)

if "%RESOLUTION%"=="4" (
    set "SCALE=-vf scale='min(960,iw)':'min(540,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"
    set "RESNAME=540p"
)

if "%RESOLUTION%"=="5" (
    set "SCALE=-vf scale='min(854,iw)':'min(480,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"
    set "RESNAME=480p"
)

if not defined RESNAME (
    echo.
    echo [ERROR] Invalid resolution.
    echo.
    goto ERROR_EXIT
)

echo.
echo.

:: ============================================================
:: OUTPUT FORMAT
:: ============================================================

echo Output format:
echo.
echo   1 = MKV
echo   2 = MP4
echo.

set "FORMAT="
set /p "FORMAT=Choose output format (default 1): "

if not defined FORMAT set "FORMAT=1"

if "%FORMAT%"=="1" set "EXT=mkv"
if "%FORMAT%"=="2" set "EXT=mp4"

if not defined EXT (
    echo.
    echo [ERROR] Invalid output format.
    echo.
    goto ERROR_EXIT
)

:: ============================================================
:: FINAL SETTINGS
:: ============================================================

echo.
echo ============================================================
echo                     FINAL SETTINGS
echo ============================================================
echo.
echo Videos:        %COUNT%
echo Codec:         AV1 / SVT-AV1
echo Resolution:    %RESNAME%
echo CRF:           %CRF%
echo Preset:        %PRESET%
echo Audio:         Opus %AUDIO%
echo Channels:      %CHANNAME%
echo Pixel format:  10-bit
echo Container:     .%EXT%
echo.
echo ============================================================
echo.

choice /C YN /N /M "Start encoding? (Y/N): "

if errorlevel 2 (
    echo.
    echo Encoding cancelled.
    echo.
    goto NORMAL_EXIT
)

if errorlevel 1 goto START_ENCODING

:: ============================================================
:: START ENCODING
:: ============================================================

:START_ENCODING

echo.
echo ============================================================
echo                    STARTING ENCODING
echo ============================================================
echo.

set /a SUCCESS=0
set /a FAILED=0

for /L %%N in (1,1,%COUNT%) do (

    echo.
    echo ============================================================
    echo                    ENCODING %%N OF %COUNT%
    echo ============================================================
    echo.

    set "CURRENT=!FILE%%N!"
    set "CURRENTNAME=!NAME%%N!"

    for %%A in ("!CURRENT!") do (
        set "BASENAME=%%~nA"
    )

    set "OUTFILE=%OUTPUT%\!BASENAME!_AV1.%EXT%"

    echo Input:
    echo !CURRENT!
    echo.
    echo Output:
    echo !OUTFILE!
    echo.
    echo Starting FFmpeg...
    echo.

    "%FFMPEG%" ^
        -hide_banner ^
        -i "!CURRENT!" ^
        -map 0:v:0 ^
        -map 0:a? ^
        -c:v libsvtav1 ^
        -preset %PRESET% ^
        -crf %CRF% ^
        !SCALE! ^
        -pix_fmt yuv420p10le ^
        -c:a libopus ^
        -b:a %AUDIO% ^
        -ac %AC% ^
        -map_metadata 0 ^
        -map_chapters 0 ^
        -y ^
        "!OUTFILE!"

    if errorlevel 1 (
        echo.
        echo ============================================================
        echo                    ENCODING FAILED
        echo ============================================================
        echo.
        echo File:
        echo !CURRENTNAME!
        echo.
        echo FFmpeg returned an error.
        echo.

        set /a FAILED+=1
    ) else (
        echo.
        echo ============================================================
        echo                   ENCODING SUCCESSFUL
        echo ============================================================
        echo.
        echo File:
        echo !CURRENTNAME!
        echo.
        echo Output:
        echo !OUTFILE!
        echo.

        set /a SUCCESS+=1
    )
)

:: ============================================================
:: COMPLETE
:: ============================================================

echo.
echo.
echo ============================================================
echo                    ENCODING COMPLETE
echo ============================================================
echo.
echo Total files: %COUNT%
echo Successful:  %SUCCESS%
echo Failed:      %FAILED%
echo.
echo Output folder:
echo %OUTPUT%
echo.
echo ============================================================
echo.

goto NORMAL_EXIT


:: ============================================================
:: ERROR EXIT
:: ============================================================

:ERROR_EXIT

echo.
echo ============================================================
echo                         ERROR
echo ============================================================
echo.
echo The encoder could not continue.
echo.
echo The window will remain open so you can read the error.
echo.

pause
exit /b 1


:: ============================================================
:: NORMAL EXIT
:: ============================================================

:NORMAL_EXIT

echo.
echo Press any key to exit...
pause >nul

exit /b 0
