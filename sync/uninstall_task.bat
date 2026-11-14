@echo off
rem Remove the daily upstream monitor task. Plain ASCII on purpose.
set "TASKNAME=MAS-ZhSyncMonitor"
schtasks /Delete /F /TN "%TASKNAME%" >nul 2>&1
if errorlevel 1 (
    echo Task "%TASKNAME%" was not registered.
) else (
    echo Removed task "%TASKNAME%".
)
if not defined MAS_NO_PAUSE pause
