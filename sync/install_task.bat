@echo off
rem Register a daily task that checks the upstream MAS repo for new commits.
rem Plain ASCII on purpose: cmd.exe reads .bat files using the system ANSI code
rem page, so UTF-8 Chinese inside a batch file gets executed as commands.
rem
rem What it does:
rem   Runs "sync\sync_upstream.py --monitor" once a day.
rem   - no upstream change -> silent, exits 0, no notification.
rem   - upstream changed    -> ONE LINE push with the new commit/tag and the
rem                           list of changed files, then exits 2.
rem It never modifies anything. The actual sync is a separate, deliberate run:
rem   python sync\sync_upstream.py --commit --release
rem
rem Why not auto-sync from the scheduler:
rem   A new upstream release almost always adds new English strings. Those need
rem   a human/agent to translate; auto-pushing them as English into a public
rem   "Traditional Chinese" repo would silently degrade it. Detection is
rem   automatic, translation stays reviewed.
rem
rem Do NOT call schtasks from PowerShell for this: the \" escape below is cmd
rem syntax and would be passed through literally, breaking /TR.

set "TASKNAME=MAS-ZhSyncMonitor"
set "PY="
for /f "delims=" %%p in ('where python 2^>nul') do if not defined PY set "PY=%%p"
if not defined PY (
    echo FAILED: python not found in PATH.
    if not defined MAS_NO_PAUSE pause
    exit /b 1
)
echo Using python: %PY%
echo Registering "%TASKNAME%" (daily 09:30) ...

schtasks /Create /F /TN "%TASKNAME%" ^
    /TR "\"%PY%\" \"%~dp0sync_upstream.py\" --monitor" ^
    /SC DAILY /ST 09:30 /RL LIMITED
if errorlevel 1 (
    echo.
    echo FAILED to register. See error above.
    if not defined MAS_NO_PAUSE pause
    exit /b 1
)

echo.
echo Registered task: "%TASKNAME%", daily 09:30.
echo.
echo   check now : run_check.bat
echo   remove    : uninstall_task.bat
echo   full sync : python sync\sync_upstream.py --commit --release
if not defined MAS_NO_PAUSE pause
