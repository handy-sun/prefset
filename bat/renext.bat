@echo off
setlocal enabledelayedexpansion

set "old_ext=.wav"
set "new_ext=.flac"

for %%F in ("*%old_ext%") do (
    set "filename=%%~nxF"
    ren "%%F" "!filename:%old_ext%=%new_ext%!"
)

endlocal