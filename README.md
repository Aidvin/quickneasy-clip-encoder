# Clip Encoder (AV1)

A simple, portable Windows video encoder using **FFmpeg**, **SVT-AV1**, and **Opus**.

This project is currently under development.

The project is designed to run from a single folder without installing FFmpeg system-wide or adding FFmpeg to the Windows PATH.

**Important:** FFmpeg is its own thing and is intentionally **not included** in this repository.

## Features

- Portable Windows setup
- No installer required for the encoder itself
- No system-wide FFmpeg installation required
- Uses SVT-AV1 for AV1 video encoding
- Uses Opus for audio
- 10-bit `yuv420p10le` output
- Batch processing of multiple videos
- Interactive CRF selection
- Interactive SVT-AV1 preset selection
- Interactive audio bitrate selection
- MKV or MP4 output
- Preserves input metadata where supported
- Automatically detects missing/incompatible FFmpeg
- Handles filenames containing spaces

## Requirements

- Windows OS
- A Windows FFmpeg build containing:
  - `libsvtav1`
  - `libopus`

The encoder does not install FFmpeg for you.

## Project structure

```text
Portable-clip-encoder/
├── Input/
├── Output/
├── Start Encoder.bat
├── encode.ps1
├── README.md
├── LICENSE
├── .gitignore
└── NOTICE.md
```

`ffmpeg.exe` is not included

## Installing FFmpeg

FFmpeg's official download page is:

https://ffmpeg.org/download.html

FFmpeg provides source code and links to Windows builds from third-party distributors. Download a Windows build that contains `ffmpeg.exe`.

After extracting the build, place **`ffmpeg.exe`** directly in the project root:

```text
Portable-clip-encoder/
├── ffmpeg.exe
├── Start Encoder.bat
├── encode.ps1
├── Input/
└── Output/
```
## Usage

1. Put one or more videos into the `Input` folder.
2. Double-click `Start Encoder.bat`.
3. Choose your CRF.
4. Choose the SVT-AV1 preset.
5. Choose the audio bitrate.
6. Choose MKV or MP4.
7. Confirm the encoding.

Encoded files are encoded to:

```text
Output/
```

For example:

```text
Input/
└── example.mkv

Output/
└── example_AV1.mkv
```

## Recommended settings

For general AV1 compression testing:

| Setting | Starting point |
|---|---:|
| Codec | SVT-AV1 |
| CRF | 30 |
| Preset | 4 |
| Audio | Opus |
| Audio bitrate | 128k |
| Pixel format | 10-bit |
| Container | MKV |

These are starting points, not universal quality recommendations. Different video content can require substantially different settings.

### CRF

Lower CRF generally produces higher quality and larger files.

Typical starting points:

```text
20  Very high quality
25  High quality
30  Good general starting point
35  Smaller files
40  Very small files
```

### Preset

Lower SVT-AV1 preset numbers generally trade more encoding time for better compression efficiency.

Preset 4 is intended as a reasonable starting point for experimentation.

## Why FFmpeg is not included

This repository contains the encoder scripts, not FFmpeg itself.

FFmpeg is a separate open-source project with its own licensing terms. FFmpeg states that most of its code is under LGPL v2.1+ while optional components can be GPL-licensed, and external libraries can affect the license of a particular build.

For that reason, this project does not redistribute an unknown third-party `ffmpeg.exe`.

See the official FFmpeg licensing information:

https://ffmpeg.org/legal.html

and:

https://ffmpeg.org/doxygen/trunk/md_LICENSE.html

The FFmpeg executable is **not covered by this repository's MIT license**.

## License

The scripts and documentation in this repository are released under the MIT License.

FFmpeg remains a separate dependency and is licensed separately.

See `LICENSE` and `NOTICE.md`.

## Disclaimer

This project is provided "as is", without warranty.

The author of this project is not affiliated with or endorsed by the FFmpeg project.

Users are responsible for complying with the licenses applicable to the FFmpeg build they choose to download and use.
- Resume support
- Logging
- Drag-and-drop encoding
