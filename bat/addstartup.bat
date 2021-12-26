@echo off
%~d0
cd %~dp0

set exeName="EngineGuardGui-i386-cl.exe"
set totalName=""
for /r %%b in (*%exeName%) do (
    if /i "%%~nxb" equ %exeName% (        
        set totalName="%%b"
        goto :find
    )
)
goto :notfind

:find
echo %totalName%

@REM x86 exe
set opt="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
@REM x64 exe
@REM set opt="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
reg add %opt% /v %exeName% /t REG_SZ /d \"%totalName%\" /f

:notfind
pause
