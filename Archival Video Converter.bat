@echo off
title Archival Video Converter
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit
setlocal enabledelayedexpansion



Rem ==========[ Config ]==========

Rem Override userDelete variable and skip input
Rem "userDeletion=" Ask for user input
Rem "userDeletion=2" Skip user input and pretend user input us 2
set "userDeletion="

Rem Override userCodec variable and skip input
Rem "userCodec=" Ask for user input
Rem "userCodec=4" Skip user input and pretend user input us 4
set "userCodec="

Rem =======[ Config Check ]=======

echo "   1 2 " | find " !userDeletion! " >nul
if errorlevel 1 (
    echo Invalid preset for userDeletion!
	timeout /t 999
	exit 1
)

echo "   1 2 3 4 5 6 7 8 9 " | find " !userCodec! " >nul
if errorlevel 1 (
    echo Invalid preset for userCodec!
	timeout /t 999
	exit 1
)

Rem ========[ Config End ]========



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

if "!userDeletion!"=="" (
	set /p userDeletion=Select number: 
) else (
	echo Select number: !userDeletion! ^(from config^)
)
echo.

echo " 1 2 " | find " !userDeletion! " >nul
if errorlevel 1 (
    cls
    goto :init
)

rem Ask user video codec
echo Which video codec is prefered and supported:
echo     ^| Device     ^| Codec  ^| Speed  ^| Quality ^| Size   ^| Compatibility
echo ----+------------+--------+--------+---------+--------+--------------
echo [1] ^| CPU ^(any^)  ^| x264   ^| medium ^| best    ^| medium ^| best
echo [2] ^| CPU ^(any^)  ^| x265   ^| slower ^| best    ^| small  ^| good
echo [3] ^| CPU ^(any^)  ^| svtav1 ^| slow   ^| best    ^| small  ^| medium
echo [4] ^| GPU Nvidia ^| h264   ^| fast   ^| better  ^| big    ^| better
echo [5] ^| GPU Nvidia ^| h265   ^| fast   ^| better  ^| medium ^| good
echo [6] ^| GPU Amd    ^| h264   ^| fast   ^| good    ^| big    ^| better
echo [7] ^| GPU Amd    ^| h265   ^| fast   ^| good    ^| medium ^| good
echo [8] ^| GPU Intel  ^| h264   ^| fast   ^| medium  ^| big    ^| better
echo [9] ^| GPU Intel  ^| h265   ^| medium ^| medium  ^| medium ^| good

if "!userCodec!"=="" (
	set /p userCodec=Select number: 
) else (
	echo Select number: !userCodec! ^(from config^)
)

echo " 1 2 3 4 5 6 7 8 9 " | find " !userCodec! " >nul
if errorlevel 1 (
    cls
    goto :init
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

rem Input & wip file path and name
set "input=!filePathNameExtension!"
set "wip=!filePathName!.!userCodec!_wip.mp4"
set "archival=!fileName!.!userCodec!_archive.mp4"

rem Skip if output already exists
if exist "!filePathName!.archive.mp4" (
	echo Skip !input!
	exit /b 0
)

rem Check if file is not from previous Run
if not "!fileName!"=="!fileName:.wip=!" (
	echo Skip !input!
	exit /b 0
)

if not "!fileName!"=="!fileName:.archive=!" (
	echo Skip !input!
	exit /b 0
)

rem Detect audio & video streams
echo Analyse !input!
set "has_audio=0"
set "has_video=0"

for /f "delims=" %%A in ('start "" /b /belownormal /wait ffprobe -v quiet -show_entries stream^=codec_type -of default^=nw^=1:nk^=1 "!input!" 2^>nul') do (
	if /i "%%A"=="audio" (
		set "has_audio=1"
	)
	if /i "%%A"=="video" (
		for /f "tokens=1" %%B in ('start "" /b /belownormal /wait ffprobe -v quiet -select_streams v:0 -show_entries stream^=nb_frames -of default^=nokey^=1:noprint_wrappers^=1 "!input!" 2^>nul') do (
			set "has_video=%%B"
		)
		if "!has_video!"=="N/A" (
			for /f "tokens=1" %%B in ('start "" /b /belownormal /wait ffprobe -v quiet -select_streams v:0 -count_frames -show_entries stream^=nb_read_frames -of default^=nokey^=1:noprint_wrappers^=1 "!input!" 2^>nul') do (
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

rem Detect bitdepth of video stream
set "pix_fmt=yuv420p"
for /f "tokens=*" %%a in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v:0 -show_entries stream^=bits_per_raw_sample -of default^=noprint_wrappers^=1:nokey^=1 "!input!" 2^>nul') do (
	if "%%a"=="10" (
		set "pix_fmt=yuv420p10le"
	)
)

rem Prepare query of same arguments
set "query="" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "!input!" -movflags +faststart -map 0:v -fps_mode vfr -map 0:a -c:a aac -b:a 192k -tag:a mp4a -pix_fmt !pix_fmt! -tag:v"

rem Run FFmpeg encoding
if "!userCodec!"=="1" (
	start !query! avc1 -c:v libx264 -crf 18 -preset placebo -x264-params ref=4 "!wip!"
)
if "!userCodec!"=="2" (
	start !query! hvc1 -c:v libx265 -crf 23 -preset placebo -x265-params ref=4:log-level=error "!wip!"
)
if "!userCodec!"=="3" (
	set SVT_LOG=1
	start !query! av01 -c:v libsvtav1 -crf 28 -preset 2 "!wip!"
)
if "!userCodec!"=="4" (
	start !query! avc1 -c:v h264_nvenc -cq 18 -preset p7 -rc vbr "!wip!"
)
if "!userCodec!"=="5" (
	start !query! hvc1 -c:v hevc_nvenc -cq 23 -preset p7 -rc vbr "!wip!"
)
if "!userCodec!"=="6" (
	start !query! avc1 -c:v h264_amf -rc cqp -cqp 18 -quality_best "!wip!"
)
if "!userCodec!"=="7" (
	start !query! hvc1 -c:v hevc_amf -rc cqp -cqp 23 -quality_best "!wip!"
)
if "!userCodec!"=="8" (
	start !query! avc1 -c:v h264_qsv -global_quality 18 -preset 1 -look_ahead 1 "!wip!"
)
if "!userCodec!"=="9" (
	start !query! hvc1 -c:v hevc_qsv -global_quality 23 -preset 1 -look_ahead 1 "!wip!"
)

if not errorlevel 0 (
	del "!wip!"
	color 0C
    echo Encoding failed
    pause
	color 07
    exit /b 1
)

rem Rename .wip to .archive
ren "!wip!" "!archival!"
if not errorlevel 0 (
	del "!wip!"
	color 0C
    echo Renaming failed
    pause
	color 07
    exit /b 1
)

rem Delete input file
if "!userDeletion!"=="2" (
	del /f "!input!"
	if not errorlevel 0 (
		color 0C
		echo Failed to delete source file
		pause
		color 07
		exit /b 1
	)
)

exit /b 0
