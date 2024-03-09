@echo off

setlocal enabledelayedexpansion
set exclude_dir=

for /f "delims=" %%i in ('dir /s /b *.MP4 ^| find /v "%cd%\%exclude_dir%\"') do (
    set s=%%i
    set s=!s:%~dp0=!
    set s=!s:\=/!
    echo ### ffmpeg.exe -i !s! -b:v 20m -crf 20 -y ..\compress\!s! ###
    ffmpeg.exe -i !s! -b:v 20m -crf 20 -y ..\compress\!s!
)
endlocal
