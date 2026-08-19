# ============================================================
# Portable AV1 Encoder
# Windows PowerShell 5.1+
#
# FFmpeg is a separate dependency and is intentionally not
# included in this repository.
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FFmpeg = Join-Path $ScriptDir "ffmpeg.exe"
$InputFolder = Join-Path $ScriptDir "Input"
$OutputFolder = Join-Path $ScriptDir "Output"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

function Pause-And-Exit {
    param(
        [int]$Code = 0
    )

    Write-Host ""
    Read-Host "Press Enter to exit" | Out-Null
    exit $Code
}

function Test-EncoderSupport {
    param(
        [string]$EncoderName
    )

    $encoderList = & $FFmpeg -hide_banner -encoders 2>&1
    return (($encoderList -join "`n") -match "(?m)^\s*[A-Z\.]+\s+$([regex]::Escape($EncoderName))\s")
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    PORTABLE AV1 ENCODER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# FFmpeg dependency check
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $FFmpeg -PathType Leaf)) {
    Write-Host "[ERROR] FFmpeg was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:" -ForegroundColor Yellow
    Write-Host "  $FFmpeg"
    Write-Host ""
    Write-Host "Download a Windows FFmpeg build from the official FFmpeg"
    Write-Host "download page and place ffmpeg.exe beside this script:"
    Write-Host "  https://ffmpeg.org/download.html"
    Write-Host ""
    Pause-And-Exit 1
}

Write-Host "[OK] FFmpeg executable found." -ForegroundColor Green

# Check that the executable can actually run.
try {
    $versionOutput = & $FFmpeg -hide_banner -version 2>&1
    $ffmpegExitCode = $LASTEXITCODE
}
catch {
    Write-Host ""
    Write-Host "[ERROR] ffmpeg.exe exists but could not be started." -ForegroundColor Red
    Write-Host "The file may be corrupted or incompatible with Windows."
    Write-Host ""
    Pause-And-Exit 1
}

if ($ffmpegExitCode -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] FFmpeg returned exit code $ffmpegExitCode during startup." -ForegroundColor Red
    Write-Host ""
    Pause-And-Exit 1
}

$versionLine = ($versionOutput | Where-Object { $_ -match "^ffmpeg version " } | Select-Object -First 1)

if ($versionLine) {
    Write-Host "[OK] $versionLine" -ForegroundColor Green
}

# Check the exact encoders this project needs.
if (-not (Test-EncoderSupport "libsvtav1")) {
    Write-Host ""
    Write-Host "[ERROR] This FFmpeg build does not provide libsvtav1." -ForegroundColor Red
    Write-Host "The encoder requires SVT-AV1 support."
    Write-Host ""
    Write-Host "Please use a full Windows FFmpeg build."
    Write-Host ""
    Pause-And-Exit 1
}

if (-not (Test-EncoderSupport "libopus")) {
    Write-Host ""
    Write-Host "[ERROR] This FFmpeg build does not provide libopus." -ForegroundColor Red
    Write-Host "The encoder requires Opus audio encoding support."
    Write-Host ""
    Write-Host "Please use a full Windows FFmpeg build."
    Write-Host ""
    Pause-And-Exit 1
}

Write-Host "[OK] libsvtav1 encoder available." -ForegroundColor Green
Write-Host "[OK] libopus encoder available." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Create folders
# ------------------------------------------------------------

foreach ($folder in @($InputFolder, $OutputFolder)) {
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# ------------------------------------------------------------
# Find videos
# ------------------------------------------------------------

$VideoExtensions = @(
    ".mp4",
    ".mkv",
    ".mov",
    ".avi",
    ".webm",
    ".m4v",
    ".wmv",
    ".flv",
    ".ts",
    ".mts",
    ".m2ts"
)

$Files = @(
    Get-ChildItem -LiteralPath $InputFolder -File -ErrorAction SilentlyContinue |
    Where-Object {
        $VideoExtensions -contains $_.Extension.ToLowerInvariant()
    }
)

if ($Files.Count -eq 0) {
    Write-Host "No supported video files were found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Place videos in:"
    Write-Host "  $InputFolder"
    Write-Host ""
    Pause-And-Exit 0
}

# ------------------------------------------------------------
# Display input files
# ------------------------------------------------------------

Write-Host "Videos found:" -ForegroundColor Green
Write-Host ""

$index = 1

foreach ($file in $Files) {
    $sizeGB = [Math]::Round(($file.Length / 1GB), 2)
    Write-Host ("{0}. {1} [{2} GB]" -f $index, $file.Name, $sizeGB)
    $index++
}

Write-Host ""
Write-Host "Total videos: $($Files.Count)"
Write-Host ""

# ------------------------------------------------------------
# CRF
# ------------------------------------------------------------

Write-Host "============================================================"
Write-Host "ENCODING SETTINGS"
Write-Host "============================================================"
Write-Host ""

Write-Host "CRF controls video quality."
Write-Host "Lower CRF = higher quality and larger files."
Write-Host ""
Write-Host "  20  Very high quality"
Write-Host "  25  High quality"
Write-Host "  30  Good starting point"
Write-Host "  35  Smaller files"
Write-Host "  40  Very small files"
Write-Host ""

$crfInput = Read-Host "Enter CRF (default 30)"

if ([string]::IsNullOrWhiteSpace($crfInput)) {
    $CRF = 30
}
else {
    if (-not [int]::TryParse($crfInput, [ref]$CRF)) {
        Write-Host ""
        Write-Host "[ERROR] CRF must be an integer from 0 to 63." -ForegroundColor Red
        Pause-And-Exit 1
    }
}

if ($CRF -lt 0 -or $CRF -gt 63) {
    Write-Host ""
    Write-Host "[ERROR] CRF must be between 0 and 63." -ForegroundColor Red
    Pause-And-Exit 1
}

# ------------------------------------------------------------
# Preset
# ------------------------------------------------------------

Write-Host ""
Write-Host "SVT-AV1 preset:"
Write-Host ""
Write-Host "  1-3   Slow / best compression"
Write-Host "  4     Recommended balance"
Write-Host "  5-7   Faster"
Write-Host "  8-13  Very fast"
Write-Host ""

$presetInput = Read-Host "Enter preset (default 4)"

if ([string]::IsNullOrWhiteSpace($presetInput)) {
    $Preset = 4
}
else {
    if (-not [int]::TryParse($presetInput, [ref]$Preset)) {
        Write-Host ""
        Write-Host "[ERROR] Preset must be an integer from 0 to 13." -ForegroundColor Red
        Pause-And-Exit 1
    }
}

if ($Preset -lt 0 -or $Preset -gt 13) {
    Write-Host ""
    Write-Host "[ERROR] Preset must be between 0 and 13." -ForegroundColor Red
    Pause-And-Exit 1
}

# ------------------------------------------------------------
# Audio bitrate
# ------------------------------------------------------------

Write-Host ""
Write-Host "Audio bitrate examples:"
Write-Host "  64k   Small"
Write-Host "  96k   Good"
Write-Host "  128k  Recommended"
Write-Host "  160k  High"
Write-Host "  192k  Very high"
Write-Host ""

$audioInput = Read-Host "Enter audio bitrate (default 128k)"

if ([string]::IsNullOrWhiteSpace($audioInput)) {
    $AudioBitrate = "128k"
}
else {
    if ($audioInput -notmatch "^\d+[kKmM]$") {
        Write-Host ""
        Write-Host "[ERROR] Audio bitrate should look like 96k, 128k, 160k, etc." -ForegroundColor Red
        Pause-And-Exit 1
    }

    $AudioBitrate = $audioInput
}

# ------------------------------------------------------------
# Container
# ------------------------------------------------------------

Write-Host ""
Write-Host "Output format:"
Write-Host "  1 = MKV"
Write-Host "  2 = MP4"
Write-Host ""

$containerInput = Read-Host "Choose output format (default 1)"

if ([string]::IsNullOrWhiteSpace($containerInput)) {
    $containerInput = "1"
}

switch ($containerInput) {
    "1" {
        $OutputExtension = ".mkv"
    }
    "2" {
        $OutputExtension = ".mp4"
    }
    default {
        Write-Host ""
        Write-Host "[ERROR] Choose 1 for MKV or 2 for MP4." -ForegroundColor Red
        Pause-And-Exit 1
    }
}

# ------------------------------------------------------------
# Confirmation
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host "FINAL SETTINGS"
Write-Host "============================================================"
Write-Host ""
Write-Host "Files:          $($Files.Count)"
Write-Host "Video codec:    AV1 / SVT-AV1"
Write-Host "CRF:            $CRF"
Write-Host "Preset:         $Preset"
Write-Host "Audio codec:    Opus"
Write-Host "Audio bitrate:  $AudioBitrate"
Write-Host "Pixel format:   yuv420p10le"
Write-Host "Container:      $OutputExtension"
Write-Host ""

$confirm = Read-Host "Start encoding? (Y/N)"

if ($confirm -notmatch "^[Yy]$") {
    Write-Host ""
    Write-Host "Encoding cancelled." -ForegroundColor Yellow
    Pause-And-Exit 0
}

# ------------------------------------------------------------
# Encode
# ------------------------------------------------------------

$total = $Files.Count
$current = 0
$successful = 0
$failed = 0
$skipped = 0

foreach ($file in $Files) {
    $current++

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "ENCODING $current OF $total" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Input:"
    Write-Host "  $($file.FullName)"
    Write-Host ""

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outputFile = Join-Path $OutputFolder ($baseName + "_AV1" + $OutputExtension)

    Write-Host "Output:"
    Write-Host "  $outputFile"
    Write-Host ""

    if (Test-Path -LiteralPath $outputFile) {
        Write-Host "Output already exists." -ForegroundColor Yellow
        $overwrite = Read-Host "Overwrite it? (Y/N)"

        if ($overwrite -notmatch "^[Yy]$") {
            Write-Host "Skipped." -ForegroundColor Yellow
            $skipped++
            continue
        }
    }

    # Use explicit arguments rather than Invoke-Expression so filenames
    # containing spaces or special characters are handled safely.
    $FFmpegArguments = @(
        "-hide_banner",
        "-y",
        "-i", $file.FullName,
        "-map", "0:v:0",
        "-map", "0:a?",
        "-c:v", "libsvtav1",
        "-preset", "$Preset",
        "-crf", "$CRF",
        "-pix_fmt", "yuv420p10le",
        "-c:a", "libopus",
        "-b:a", "$AudioBitrate",
        "-map_metadata", "0",
        $outputFile
    )

    Write-Host "Starting FFmpeg..." -ForegroundColor Green
    Write-Host ""

    try {
        & $FFmpeg @FFmpegArguments
        $exitCode = $LASTEXITCODE
    }
    catch {
        $exitCode = 1
        Write-Host ""
        Write-Host "Exception while starting FFmpeg:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Write-Host ""

    if ($exitCode -eq 0) {
        Write-Host "ENCODING SUCCESSFUL" -ForegroundColor Green
        $successful++
    }
    else {
        Write-Host "ENCODING FAILED (FFmpeg exit code $exitCode)" -ForegroundColor Red
        $failed++
    }
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    ENCODING COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total:       $total"
Write-Host "Successful:  $successful" -ForegroundColor Green
Write-Host "Failed:      $failed" -ForegroundColor Red
Write-Host "Skipped:     $skipped" -ForegroundColor Yellow
Write-Host ""
Write-Host "Output folder:"
Write-Host "  $OutputFolder"
Write-Host ""

if ($failed -gt 0) {
    Pause-And-Exit 2
}

Pause-And-Exit 0
