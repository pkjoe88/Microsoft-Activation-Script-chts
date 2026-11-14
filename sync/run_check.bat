@echo off
rem Run the upstream check immediately and keep the window open so the result
rem is readable. Plain ASCII on purpose.
cd /d "%~dp0.."
python sync\sync_upstream.py --check-only
echo.
echo exit code: %errorlevel%
echo   0 = up to date
echo   1 = upstream has new commits
if not defined MAS_NO_PAUSE pause
