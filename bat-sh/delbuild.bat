@echo off
set d=*
if "%1" NEQ "" (
    set d=%1
)
cd %d%
for /d /r %%i in (*) do (
    echo %%i | findstr "\build" >nul && echo del %%i && rmdir /s /q %%i
)