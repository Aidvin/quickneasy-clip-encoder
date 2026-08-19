@echo off
setlocal

REM ============================================================
REM Portable AV1 Encoder - Windows launcher
REM FFmpeg is a separate dependency and is NOT included.
REM ============================================================

cd /d "%~dp0"

title Portable AV1 Encoder

echo.
echo ============================================================
echo                    PORTABLE AV1 ENCODER
echo ============================================================
echo.

if not exist "%~dp0ffmpeg.exe" (
    echo [ERROR] FFmpeg was not found.
    echo.
    echo Expected:
    echo   %~dp0ffmpeg.exe
    echo.
    echo Please download a Windows FFmpeg build and place
    echo ffmpeg.exe in the same folder as this BAT file.
    echo.
    echo See README.md for instructions.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0encode.ps1" (
    echo [ERROR] encode.ps1 was not found.
    echo.
    echo Expected:
    echo   %~dp0encode.ps1
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0encode.ps1"

set "EXITCODE=%ERRORLEVEL%"

echo.
if "%EXITCODE%"=="0" (
    echo Encoder finished successfully.
) else (
    echo Encoder exited with code %EXITCODE%.
)

echo.
pause
exit /b %EXITCODE%
