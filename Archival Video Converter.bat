@echo off
title Archival Video Converter
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit
setlocal enabledelayedexpansion



Rem	Copyright (C) 2025 Alpar Duman
Rem	This file is part of archival-video-converter-batch.
Rem	
Rem	archival-video-converter-batch is free software: you can redistribute it and/or modify
Rem	it under the terms of the GNU General Public License version 3 as
Rem	published by the Free Software Foundation.
Rem	
Rem	archival-video-converter-batch is distributed in the hope that it will be useful,
Rem	but WITHOUT ANY WARRANTY; without even the implied warranty of
Rem	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
Rem	GNU General Public License for more details.
Rem	
Rem	You should have received a copy of the GNU General Public License
Rem	along with archival-video-converter-batch. If not, see
Rem	<https://github.com/AlparDuman/archival-video-converter-batch/blob/main/LICENSE>
Rem	else <https://www.gnu.org/licenses/>.

:init
echo     _             _     _            _  __     ___     _               ____                          _            
echo    / \   _ __ ___^| ^|__ (_)_   ____ _^| ^| \ \   / (_) __^| ^| ___  ___    / ___^|___  _ ____   _____ _ __^| ^|_ ___ _ __ 
echo   / _ \ ^| '__/ __^| '_ \^| \ \ / / _` ^| ^|  \ \ / /^| ^|/ _` ^|/ _ \/ _ \  ^| ^|   / _ \^| '_ \ \ / / _ \ '__^| __/ _ \ '__^|
echo  / ___ \^| ^| ^| (__^| ^| ^| ^| ^|\ V / (_^| ^| ^|   \ V / ^| ^| (_^| ^|  __/ (_) ^| ^| ^|__^| (_) ^| ^| ^| \ V /  __/ ^|  ^| ^|^|  __/ ^|   
echo /_/   \_\_^|  \___^|_^| ^|_^|_^| \_/ \__,_^|_^|    \_/  ^|_^|\__,_^|\___^|\___/   \____\___/^|_^| ^|_^|\_/ \___^|_^|   \__\___^|_^|   
echo v1.0 ================================================ https://github.com/AlparDuman/archival-video-converter-batch
echo.



rem Check for dependencies
where ffmpeg >nul 2>&1 || (
	echo No ffmpeg installation found, how can this be fixed:
	echo 1^) Download from https://www.ffmpeg.org/download.html
	echo 2^) Add the folder containing ffmpeg.exe to the environment variables.
	exit /b 1
)

where ffprobe >nul 2>&1 || (
	echo No ffprobe installation found, how can this be fixed:
	echo 1^) Download from https://www.ffmpeg.org/download.html
	echo 2^) Add the folder containing ffprobe.exe to the environment variables.
	exit /b 1
)

rem Ask user what to do with original video file after successful convertion
echo What to do with original video file after successful convertion:
echo [1] Keep original video file
echo [2] Delete original video file
set /p userDeletion=Select number: 
echo.

if not "!userDeletion!"=="1" (
	if not "!userDeletion!"=="2" (
		cls
		goto :init
	)
)

rem Ask user video codec
echo Which video codec is prefered:
echo     ^| Device     ^| Codec ^| Speed ^| Quality ^| Size  ^| Compatibility
echo ----+------------+-------+-------+---------+-------+--------------
echo [1] ^| any CPU    ^| x264  ^| base  ^| best    ^| base  ^| best
echo [2] ^| any CPU    ^| x265  ^| x0.09 ^| best    ^| x0.79 ^| most
echo [3] ^| Nvidia GPU ^| h264  ^| x8.5  ^| good    ^| x3.25 ^| best
echo [4] ^| Nvidia GPU ^| h265  ^| x9    ^| good    ^| x1.5  ^| most
set /p userCodec=Select number: 

if not "!userCodec!"=="1" (
	if not "!userCodec!"=="2" (
		if not "!userCodec!"=="3" (
			if not "!userCodec!"=="4" (
				cls
				goto :init
			)
		)
	)
)

rem Go through each argument, could be a folder or a file
for %%F in (%*) do (
	if exist "%%~F\" (
		call :process_folder "%%~F\"
	) else (
		call :process_file "%%~F"
	)
)

rem Finished
timeout /t 999
exit 0



:process_folder

for /R "%~1" %%I in (*) do (
	call :process_file "%%~I"
)
exit /b 0



:process_file
echo.

rem Escape file name, path & extension
set "filePathNameExtension=%~dpnx1"
set "filePathName=%~dpn1"
set "fileName=%~n1"

rem Skip if output already exists
if exist "!filePathName!.archive.mp4" (
	echo Skip !filePathNameExtension!
	exit /b 0
)

rem Check if file is not from previous Run
if not "!fileName!"=="!fileName:.wip=!" (
	echo Skip !filePathNameExtension!
	exit /b 0
)

if not "!fileName!"=="!fileName:.archive=!" (
	echo Skip !filePathNameExtension!
	exit /b 0
)

rem Detect audio & video streams
echo Analyse !filePathNameExtension!
set "has_audio=0"
set "has_video=0"

for /f "delims=" %%A in ('ffprobe -v quiet -show_entries stream^=codec_type -of default^=nw^=1:nk^=1 "!filePathNameExtension!" 2^>nul') do (
	if /i "%%A"=="audio" (
		set "has_audio=1"
	)
	if /i "%%A"=="video" (
		for /f "tokens=1" %%B in ('ffprobe -v quiet -select_streams v:0 -show_entries stream^=nb_frames -of default^=nokey^=1:noprint_wrappers^=1 "!filePathNameExtension!" 2^>nul') do (
			set "has_video=%%B"
		)
		if "!has_video!"=="N/A" (
			for /f "tokens=1" %%B in ('ffprobe -v quiet -select_streams v:0 -count_frames -show_entries stream^=nb_read_frames -of default^=nokey^=1:noprint_wrappers^=1 "!filePathNameExtension!" 2^>nul') do (
				set "has_video=%%B"
			)
		)
	)
)

rem Check for audio
if !has_audio! equ 0 (
	echo Skip, not a video file
	exit /b 0
)

rem Check for images
for /f "delims=0123456789" %%A in ("!has_video!") do (
	echo Skip, not a video file
	exit /b 0
)
if !has_video! leq 1 (
	echo Skip, not a video file
	exit /b 0
)

rem Input & wip file path and name
set "input=!filePathNameExtension!"
set "wip=!filePathNameExtension!.wip.mp4"


rem Run FFmpeg encoding (adjust command as needed)
if "!userCodec!"=="1" (
	start "" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "%input%" -movflags +faststart -map 0:v -fps_mode vfr -map 0:a -c:a aac -b:a 192k -tag:a mp4a -crf 18 -tag:v avc1 -c:v libx264 -pix_fmt yuv420p -preset placebo -x264-params ref=4 "%wip%"
)
if "!userCodec!"=="2" (
	start "" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "%input%" -movflags +faststart -map 0:v -fps_mode vfr -map 0:a -c:a aac -b:a 192k -tag:a mp4a -crf 23 -tag:v hvc1 -c:v libx265 -pix_fmt yuv420p -preset placebo -x265-params ref=4:log-level=error "%wip%"
)
if "!userCodec!"=="3" (
	start "" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "%input%" -movflags +faststart -map 0:v -fps_mode vfr -map 0:a -c:a aac -b:a 192k -tag:a mp4a -cq 18 -tag:v avc1 -c:v h264_nvenc -pix_fmt yuv420p -preset p7 -rc vbr "%wip%"
)
if "!userCodec!"=="4" (
	start "" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "%input%" -movflags +faststart -map 0:v -fps_mode vfr -map 0:a -c:a aac -b:a 192k -tag:a mp4a -cq 23 -tag:v hvc1 -c:v hevc_nvenc -pix_fmt yuv420p -preset p7 -rc vbr "%wip%"
)
if not errorlevel 0 (
	del "%wip%"
    echo Encoding failed.
    pause
    exit /b 1
)

rem Rename .wip to .archive
ren "%wip%" "!fileName!.archive.mp4"
if not errorlevel 0 (
	del "%wip%"
    echo Renaming failed.
    pause
    exit /b 1
)

rem Delete input file
if "!userDeletion!"=="2" (
	del /f "%input%"
	if not errorlevel 0 (
		echo Failed to delete source file.
		pause
		exit /b 1
	)
)

exit /b 0

