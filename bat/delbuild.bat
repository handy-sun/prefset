@echo off
set drt=%~dp0
if "%1" NEQ "" (
    set drt=%1
)
echo %drt%
cd %drt%
for /d /r %%i in (*) do (
    echo %%i | findstr "\build" >nul && echo rmdir %%i && rmdir /s /q %%i
)