@echo off
@REM dir 命令 /s 查找当前目录以及所有子目录下的文件 /b 舍弃标题与摘要内容
setlocal enabledelayedexpansion
set exclude_dir=
for /f "delims=" %%i in ('dir /s /b *.json;*.exe ^| find /v "%cd%\%exclude_dir%\"') do (
    set s=%%i
    set s=!s:%~dp0=!
    set s=!s:\=/!
    echo !s!
)
endlocal