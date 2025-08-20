# Archival Video Converter Batch

A simple windows batch file to convert videos for archiving using drag & drop using [FFmpeg](https://www.ffmpeg.org/).

| Table of Contents |
| - |
| [Dependency](#dependency) |
| [Installation](#installation) |
| [Usage](#usage) |

## Dependency

The folder containing the FFmpeg.exe and FFprobe.exe files must be included in the environment variables. These can be downloaded [here](https://www.ffmpeg.org/download.html).

## Installation

Move the file 'Archival Video Converter.bat' to a location where you can drag and drop the video files you want to convert, such as the desktop.

## Usage

Drag and drop video files or folders containing video files onto this batch file. Please note that Windows has a character limit for drag and drop operations. If you want to process a large number of files, first move them to a folder and then drag that folder onto the batch file.

Next, you will be asked to specify whether the script should delete the original video file after successful conversion and which codec should be used for the video. You can select the option that suits your requirements. x264 is recommended for best compatibility with old and new devices and possible licensing requirements with x265 alias hevc.
