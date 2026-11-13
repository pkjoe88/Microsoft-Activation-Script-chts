@set masver=3.14
@echo off



::============================================================================
::
::   Homepage: m{}assgrave{dot}dev
::
::============================================================================



::========================================================================================================================================

::  Set environment variables, it helps if they are misconfigured in the system

setlocal EnableExtensions
setlocal DisableDelayedExpansion

set "PathExt=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"

set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)

set "ComSpec=%SysPath%\cmd.exe"
set "PSModulePath=%ProgramFiles%\WindowsPowerShell\Modules;%SysPath%\WindowsPowerShell\v1.0\Modules"

cd /d "%SysPath%"

:: Workaround for https://github.com/microsoft/terminal/issues/15212, when %0 starts with a quote %0 parameter expansion is not specialcased.
:: Changing %0 to something that is not quoted bypasses the issue.
goto arg_workaround_end
:arg_workaround
set "_cmdf=%~f0"
exit /b
:arg_workaround_end

call :arg_workaround

set re1=
set re2=
set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="re1" set re1=1
if /i "%%#"=="re2" set re2=1
if /i "%%#"=="-qedit" (set re1=1&set re2=1)
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

if exist %SystemRoot%\Sysnative\cmd.exe if not defined re1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* re1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined re2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* re2"
exit /b
)

::========================================================================================================================================

set "blank="
set "mas=ht%blank%tps%blank%://m%blank%ass%blank%grave.dev/"
set "github=ht%blank%tps%blank%://github.com/m%blank%assgra%blank%vel/Micro%blank%soft-Acti%blank%vation-Scripts"
set "selfgit=ht%blank%tps%blank%://git.acti%blank%vated.win/Micr%blank%osoft-Act%blank%ivation-Scripts"

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING"
if %errorlevel% NEQ 0 (
echo:
echo Null 服務未執行，腳本可能會當機...
echo:
echo:
echo 請查看此網頁尋求協助 - %mas%fix_service
echo:
echo:
ping 127.0.0.1 -n 20
)
cls

::  Check LF line ending

>nul findstr /v "$" "%_cmdf%" && (
echo:
echo 錯誤 - 腳本的換行格式有 LF 問題，或腳本結尾缺少一行空行。
echo:
echo:
echo 請查看此網頁尋求協助 - %mas%troubleshoot
echo:
echo:
ping 127.0.0.1 -n 20 >nul
exit /b
)

::========================================================================================================================================

cls
color 07
title  疑難排解 %masver%

set _args=
set _elev=
set _unattended=0

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args set _args=%_args:re1=%
if defined _args set _args=%_args:re2=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"                    set _elev=1
)
)

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

call :dk_setvar
set "line=_________________________________________________________________________________________________"

::========================================================================================================================================

if %winbuild% EQU 1 (
%eline%
echo 無法偵測 Windows 組建編號。
echo:
setlocal EnableDelayedExpansion
set fixes=%fixes% %mas%troubleshoot
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%troubleshoot"
goto dk_done
)

if exist "%Systemdrive%\Users\WDAGUtilityAccount" (
sc query gcs | find /i "RUNNING" %nul% && (
%eline%
echo 偵測到 Windows Sandbox。
echo 系統缺少授權元件，腳本無法執行。正在中止...
echo:
goto dk_done
)
)

if %winbuild% LSS 6001 (
%nceline%
echo 偵測到不支援的作業系統版本 [%winbuild%]。
echo MAS 僅支援 Windows Vista/7/8/8.1/10/11 與對應的 Server 版本。
if %winbuild% EQU 6000 (
echo:
echo 不支援 Windows Vista RTM，因為無法安裝 PowerShell。
echo 請升級至 Windows Vista SP1 或 SP2。
)
goto dk_done
)

if %winbuild% LSS 7600 if not exist "%SysPath%\WindowsPowerShell\v1.0\Modules" (
%nceline%
if not exist %ps% (
echo 系統未安裝 PowerShell。
)
echo 請從下列網址安裝 PowerShell 2.0。
echo:
echo https://www.catalog.update.microsoft.com/Search.aspx?q=KB968930
if %_unattended%==0 start https://www.catalog.update.microsoft.com/Search.aspx?q=KB968930
goto dk_done
)

::========================================================================================================================================

::  Fix special character limitations in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batp=%_cmdf:'=''%"

set _PSarg="""%_cmdf%""" -el %_args%
set _PSarg=%_PSarg:'=''%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_cmdf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo 腳本是從暫存資料夾啟動的。
echo 您很可能是直接在壓縮檔內執行腳本。
echo:
echo 請先解壓縮檔案，再從解壓後的資料夾啟動腳本。
goto dk_done
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && exit /b
%eline%
echo 此腳本需要系統管理員權限。
echo 請以滑鼠右鍵按一下此腳本，然後選擇「以系統管理員身分執行」。
goto dk_done
)

::========================================================================================================================================

::  Check PowerShell

::pstst $ExecutionContext.SessionState.LanguageMode :pstst

for /f "delims=" %%a in ('%psc% "if ($PSVersionTable.PSEdition -ne 'Core') {$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':pstst';. ([scriptblock]::Create($f[1]))}" %nul6%') do (set tstresult=%%a)

if /i not "%tstresult%"=="FullLanguage" (
%eline%
for /f "delims=" %%a in ('%psc% "$ExecutionContext.SessionState.LanguageMode" %nul6%') do (set tstresult2=%%a)
echo 測試 1 - %tstresult%
echo 測試 2 - !tstresult2!
echo:

REM check LanguageMode

echo: !tstresult2! | findstr /i "ConstrainedLanguage RestrictedLanguage NoLanguage" %nul1% && (
echo PowerShell 未處於 FullLanguage 模式。正在中止...
echo 如果您曾對 PowerShell 套用限制，請先復原那些變更。
set fixes=%fixes% %mas%fix_powershell
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%fix_powershell"
goto dk_done
)

REM check Powershell core version

cmd /c "%psc% "$PSVersionTable.PSEdition"" | find /i "Core" %nul1% && (
echo MAS 需要 Windows PowerShell，但系統中的 PowerShell 似乎已被 PowerShell Core 取代。正在中止...
set fixes=%fixes% %mas%in-place_repair_upgrade
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%in-place_repair_upgrade"
goto dk_done
)

REM check for Mal-ware that may cause issues with Powershell

for /r "%ProgramFiles%\" %%f in (secureboot.exe) do if exist "%%f" (
echo "%%f"
echo 偵測到惡意軟體，PowerShell 無法正常運作。
set fixes=%fixes% %mas%remove_mal%w%ware
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%remove_mal%w%ware"
goto dk_done
)

REM check if .NET is working properly

if /i "!tstresult2!"=="FullLanguage" (
cmd /c "%psc% ""try {[System.AppDomain]::CurrentDomain.GetAssemblies(); [System.Math]::Sqrt(144)} catch {Exit 3}""" %nul%
if !errorlevel!==3 (
echo Windows PowerShell 無法載入 .NET 命令。正在中止...
set fixes=%fixes% %mas%in-place_repair_upgrade
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%in-place_repair_upgrade"
goto dk_done
)
)

REM check antivirus and other errors

echo PowerShell 無法正常運作。正在中止...

if /i "!tstresult2!"=="FullLanguage" (
echo:
echo 您的防毒軟體可能封鎖了此腳本。
echo:
sc query sense | find /i "RUNNING" %nul% && (
echo 已安裝的防毒軟體 - Microsoft Defender for Endpoint
)
cmd /c "%psc% ""$av = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct; $n = @(); foreach ($i in $av) { $n += $i.displayName }; if ($n) { Write-Host ('Installed Antivirus - ' + ($n -join ', '))}"""
)

set fixes=%fixes% %mas%troubleshoot
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%troubleshoot"
goto dk_done
)

::========================================================================================================================================

::  Disable QuickEdit and launch from conhost.exe to avoid Terminal app

if %winbuild% GEQ 17763 (
set terminal=1
) else (
set terminal=
)

::  Check if script is running in Terminal app

if defined terminal (
set lines=0
for /f "skip=3 tokens=* delims=" %%A in ('mode con') do if "!lines!"=="0" (
for %%B in (%%A) do set lines=%%B
)
if !lines! GEQ 100 set terminal=
)

if %_unattended%==1 goto :skipQE
for %%# in (%_args%) do (if /i "%%#"=="-qedit" goto :skipQE)

::  Relaunch to disable QuickEdit in the current session and use conhost.exe instead of the Terminal app
::  This code disables QuickEdit for the current cmd.exe session without making permanent registry changes
::  It is included because clicking on the script window can pause execution, causing confusion that the script has stopped due to an error

set resetQE=1
reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% && set resetQE=0
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d 0 /f %nul1%

if defined terminal (
start conhost.exe "!_cmdf!" %_args% -qedit
start reg add HKCU\Console /v QuickEdit /t REG_DWORD /d %resetQE% /f %nul1%
exit /b
) else if %resetQE% EQU 1 (
start cmd.exe /c ""!_cmdf!" %_args% -qedit"
start reg add HKCU\Console /v QuickEdit /t REG_DWORD /d %resetQE% /f %nul1%
exit /b
)

:skipQE

::========================================================================================================================================

::  Check for updates

set -=
set old=
set pingp=
set upver=%masver:.=%

for %%A in (
activ%-%ated.win
mass%-%grave.dev
) do if not defined pingp (
for /f "delims=[] tokens=2" %%B in ('ping -n 1 %%A') do (
if not "%%B"=="" (set old=1& set pingp=1)
for /f "delims=[] tokens=2" %%C in ('ping -n 1 updatecheck%upver%.%%A') do (
if not "%%C"=="" set old=
)
)
)

if defined old (
echo ________________________________________________
%eline%
echo 您的 MAS 版本 [%masver%] 已過期。
echo ________________________________________________
echo:
if not %_unattended%==1 (
echo [1] 取得最新版 MAS
echo [0] 仍要繼續
echo:
call :dk_color %_Green% "請以鍵盤選擇選單選項 [1,0]："
choice /C:10 /N
if !errorlevel!==2 rem
if !errorlevel!==1 (start %selfgit% & start %github% & start %mas% & exit /b)
)
)

::========================================================================================================================================

setlocal DisableDelayedExpansion

::  Check desktop location

set desktop=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "desktop=%%b"
if not defined desktop for /f "delims=" %%a in ('%psc% "& {write-host $([Environment]::GetFolderPath('Desktop'))}"') do call set "desktop=%%a"

if not defined desktop (
%eline%
echo 無法偵測桌面位置，正在中止...
goto dk_done
)

setlocal EnableDelayedExpansion

::========================================================================================================================================

:at_menu

cls
color 07
title  疑難排解 %masver%
if not defined terminal mode 77, 30

echo:
echo:
echo:
echo:
echo:       _______________________________________________________________
echo:                                                   
call :dk_color2 %_White% "             [1] " %_Green% "說明"
echo:             ___________________________________________________
echo:                                                                      
echo:             [2] Dism RestoreHealth
echo:             [3] SFC Scannow
echo:                                                                      
echo:             [4] 修復 WMI
echo:             [5] 修復授權
echo:             [6] 修復 WPA 登錄檔
echo:             ___________________________________________________
echo:
echo:             [0] %_exitmsg%
echo:       _______________________________________________________________
echo:          
call :dk_color2 %_White% "            " %_Green% "請以鍵盤選擇選單選項："
choice /C:1234560 /N
set _erl=%errorlevel%

if %_erl%==7 exit /b
if %_erl%==6 start %mas%fix-wpa-registry &goto at_menu
if %_erl%==5 goto:retokens
if %_erl%==4 goto:fixwmi
if %_erl%==3 goto:sfcscan
if %_erl%==2 goto:dism_rest
if %_erl%==1 (start %selfgit% & start %github% & start %mas%troubleshoot & goto at_menu)
goto :at_menu

::========================================================================================================================================

:dism_rest

cls
if not defined terminal mode 98, 30
title  Dism /English /Online /Cleanup-Image /RestoreHealth

if %winbuild% LSS 9200 (
%eline%
echo 偵測到不支援的作業系統版本。
echo 此命令僅適用於 Windows 8/8.1/10/11 與對應的 Server 版本。
goto :at_back
)

set _int=
for %%a in (l.root-servers.net resolver1.opendns.com download.windowsupdate.com google.com) do if not defined _int (
for /f "delims=[] tokens=2" %%# in ('ping -n 1 %%a') do (if not "%%#"=="" set _int=1)
)

echo:
if defined _int (
echo      正在檢查網際網路連線  [已連線]
) else (
call :dk_color2 %_White% "     " %Red% "正在檢查網際網路連線  [未連線]"
)

echo %line%
echo:
echo      DISM 會使用 Windows Update 提供修復損毀所需的取代檔案。
echo      這需要 5-15 分鐘或更久..
echo %line%
echo:
echo      注意事項：
echo:
call :dk_color2 %_White% "     - " %Gray% "請確認已連上網際網路。"
call :dk_color2 %_White% "     - " %Gray% "請確認 Windows Update 正常運作。"
echo:
echo %line%
echo:
choice /C:09 /N /M ">    [9] 繼續 [0] 返回 : "
if %errorlevel%==1 goto at_menu

cls
if not defined terminal mode 110, 30

for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

%psc% Stop-Service TrustedInstaller -force %nul%

copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\backup_cbs_%_time%.log" %nul%
copy /y /b "%SystemRoot%\logs\DISM\dism.log" "%SystemRoot%\logs\DISM\backup_dism_%_time%.log" %nul%
del /f /q "%SystemRoot%\logs\cbs\cbs.log" %nul%
del /f /q "%SystemRoot%\logs\DISM\dism.log" %nul%

echo:
echo 正在套用命令...
echo dism /english /online /cleanup-image /restorehealth
dism /english /online /cleanup-image /restorehealth

timeout /t 5 %nul1%
copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\cbs_%_time%.log" %nul%
copy /y /b "%SystemRoot%\logs\DISM\dism.log" "%SystemRoot%\logs\DISM\dism_%_time%.log" %nul%

if not exist "!desktop!\AT_Logs\" md "!desktop!\AT_Logs\" %nul%
call :compresslog cbs\cbs_%_time%.log AT_Logs\RHealth_CBS %nul%
call :compresslog DISM\dism_%_time%.log AT_Logs\RHealth_DISM %nul%

if not exist "!desktop!\AT_Logs\RHealth_CBS_%_time%.cab" (
copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "!desktop!\AT_Logs\RHealth_CBS_%_time%.log" %nul%
)

if not exist "!desktop!\AT_Logs\RHealth_DISM_%_time%.cab" (
copy /y /b "%SystemRoot%\logs\DISM\dism.log" "!desktop!\AT_Logs\RHealth_DISM_%_time%.log" %nul%
)

echo:
call :dk_color %Gray% "CBS 與 DISM 記錄檔已複製到桌面上的 AT_Logs 資料夾。"
goto :at_back

::========================================================================================================================================

:sfcscan

cls
if not defined terminal mode 98, 30
title  sfc /scannow

echo:
echo %line%
echo:    
echo      SFC 會修復遺失或損毀的系統檔案。
echo      建議您先執行 DISM 選項，再執行這個選項。
echo      這需要 10-15 分鐘或更久..
echo:
echo      如果 SFC 無法修復某些項目，請再次執行命令，看看下次是否能夠修復。
echo      有時可能需要執行 sfc /scannow 命令 3 次，
echo      並在每次執行後重新啟動電腦，才能完全修復它所有能修復的項目。
echo:   
echo %line%
echo:
choice /C:09 /N /M ">    [9] 繼續 [0] 返回 : "
if %errorlevel%==1 goto at_menu

cls
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

%psc% Stop-Service TrustedInstaller -force %nul%

copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\backup_cbs_%_time%.log" %nul%
del /f /q "%SystemRoot%\logs\cbs\cbs.log" %nul%

echo:
echo 正在套用命令...
echo sfc /scannow
sfc /scannow

timeout /t 5 %nul1%
copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\cbs_%_time%.log" %nul%

if not exist "!desktop!\AT_Logs\" md "!desktop!\AT_Logs\" %nul%
call :compresslog cbs\cbs_%_time%.log AT_Logs\SFC_CBS %nul%

if not exist "!desktop!\AT_Logs\SFC_CBS_%_time%.cab" (
copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "!desktop!\AT_Logs\SFC_CBS_%_time%.log" %nul%
)

echo:
call :dk_color %Gray% "CBS 記錄檔已複製到桌面上的 AT_Logs 資料夾。"
goto :at_back

::========================================================================================================================================

:retokens

cls
if not defined terminal (
mode 125, 32
%psc% "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=200;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}" %nul%
)
title  修復授權 ^(ClipSVC ^+ SPP ^+ OSPP^)

if %winbuild% EQU 6001 (
%eline%
echo Windows Vista SP1 不支援此選項。
echo 請升級至 Windows Vista SP2。
goto :at_back
)

echo:
echo %line%
echo:   
echo      注意事項：
echo:
echo       - 此選項有助於疑難排解啟用問題。
echo:
echo       - 此選項將會：
echo            - 停用 Windows 與 Office，您可能需要重新啟用。
echo              如果 Windows 是以主機板／OEM／數位授權啟用，
echo              則 Windows 之後會自行重新啟用。
echo:
echo            - 清除 ClipSVC、SPP 與 OSPP 授權。
echo            - 修復 SPP token 資料夾與登錄檔的權限。
echo            - 觸發 Office 的修復選項。
echo:
call :dk_color2 %_White% "      - " %Blue% "僅在必要時套用此選項。"
echo:
echo %line%
echo:
choice /C:09 /N /M ">    [9] 繼續 [0] 返回 : "
if %errorlevel%==1 goto at_menu

::========================================================================================================================================

::  Rebuild ClipSVC Licences

cls
:cleanlicensing

echo:
echo %line%
echo:
call :dk_color %Blue% "正在重建 ClipSVC 授權..."
echo:

if %winbuild% LSS 10240 (
echo 僅支援在 Windows 10/11 上重建 ClipSVC 授權。
echo 正在略過...
goto :rebuildspptok
)

%psc% "(([WMISEARCHER]'SELECT Name FROM SoftwareLicensingProduct WHERE LicenseStatus=1 AND GracePeriodRemaining=0 AND PartialProductKey IS NOT NULL AND LicenseDependsOn is NULL').Get()).Name" %nul2% | findstr /i "Windows" %nul1% && (
echo Windows 已永久啟用。
echo 正在略過...
goto :rebuildspptok
)

set _partial=
set _keymatch=
for /f "tokens=2 delims==" %%# in ('%psc% "(([WMISEARCHER]'SELECT PartialProductKey FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL AND LicenseDependsOn is NULL').Get()).PartialProductKey | %% {echo ('PartialProductKey='+$_)}" %nul6%') do set "_partial=%%#"
for %%# in (8HV2C QPFCT 3V66T PKCKT WXCHW 8TYMD 6F4BT 8HVX7 KD72Y 7CFBY DRR8H P39PB DYJWX MDWWW 9HKR4 M7V2X 2YV77 WT2RQ MHBPB QPF8P 2YV66 VMJ2C DJ4F6 CKFFD YY74H J8JXD BHDCD T6R4W D32MH RRK69 3PJBP) do if /i "%_partial%"=="%%#" set _keymatch=1

if not defined _keymatch (
echo 未安裝 HWID 啟用金鑰。
echo 正在略過...
goto :rebuildspptok
)

%psc% "If([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet){Exit 0}Else{Exit 1}"
if errorlevel 1 (
echo 網際網路未連線。
echo 正在略過...
goto :rebuildspptok
)

set resfail=
for %%# in (
licensing.mp.microsoft.com/v7.0/licenses/content
login.live.com/ppsecure/deviceaddcredential.srf
purchase.mp.microsoft.com/v7.0/users/me/orders
) do if not defined resfail (
%psc% "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; irm https://%%# -Method POST } catch { if ($_.Exception.Response -eq $null) { Write-Host """"[%%#] $($_.Exception.Message)"""" -ForegroundColor Red -BackgroundColor Black; exit 3 } }"
if !errorlevel!==3 set resfail=1
)

if defined resfail (
echo 無法連線到授權伺服器。
echo 正在略過...
goto :rebuildspptok
)

echo 正在停止 ClipSVC 服務...
%psc% Stop-Service ClipSVC -force %nul%
timeout /t 2 %nul%

echo:
echo 正在套用清除 ClipSVC 授權的命令...
echo rundll32 clipc.dll,ClipCleanUpState

rundll32 clipc.dll,ClipCleanUpState

if %winbuild% LEQ 10240 (
echo [成功]
) else (
if exist "%ProgramData%\Microsoft\Windows\ClipSVC\tokens.dat" (
call :dk_color %Red% "[失敗]"
) else (
echo [成功]
)
)

::  Below registry key (Volatile & Protected) gets created after the ClipSVC License cleanup command, and gets automatically deleted after 
::  system restart. It needs to be deleted to activate the system without restart.

set "RegKey=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState"
set "_ident=HKU\S-1-5-19\SOFTWARE\Microsoft\IdentityCRL"

reg query "%RegKey%" %nul% && %nul% call :regownstart
reg delete "%RegKey%" /f %nul% 

echo:
echo 正在刪除 Volatile 與受保護的登錄檔機碼...
echo [%RegKey%]
reg query "%RegKey%" %nul% && (
call :dk_color %Red% "[失敗]"
echo 請使用「重新啟動」選項重新開機，系統會自動刪除此登錄檔機碼。
) || (
echo [成功]
)

::   Clear HWID token related registry to fix activation incase there is any corruption

echo:
echo 正在刪除 IdentityCRL 登錄檔機碼...
echo [%_ident%]
reg delete "%_ident%" /f %nul%
reg query "%_ident%" %nul% && (
call :dk_color %Red% "[失敗]"
) || (
echo [成功]
)

%psc% Stop-Service ClipSVC -force %nul%

::  Rebuild ClipSVC folder to fix permission issues

echo:
if %winbuild% GTR 10240 (
echo 正在刪除資料夾 %ProgramData%\Microsoft\Windows\ClipSVC\
rmdir /s /q "C:\ProgramData\Microsoft\Windows\ClipSvc" %nul%

if exist "%ProgramData%\Microsoft\Windows\ClipSVC\" (
call :dk_color %Red% "[失敗]"
) else (
echo [成功]
)

echo:
echo 正在重建 %ProgramData%\Microsoft\Windows\ClipSVC\ 資料夾...
%psc% Start-Service ClipSVC %nul%
timeout /t 3 %nul%
if not exist "%ProgramData%\Microsoft\Windows\ClipSVC\" timeout /t 5 %nul%
if not exist "%ProgramData%\Microsoft\Windows\ClipSVC\" (
call :dk_color %Red% "[失敗]"
) else (
echo [成功]
)
)

echo:
echo 正在重新啟動 wlidsvc 與 LicenseManager 服務...
for %%# in (wlidsvc LicenseManager) do (%psc% "Start-Job { Restart-Service %%# } | Wait-Job -Timeout 20 | Out-Null")

::========================================================================================================================================

::  Rebuild SPP Tokens

:rebuildspptok

echo:
echo %line%
echo:
call :dk_color %Blue% "正在重建 SPP 授權 token..."
echo:

echo 正在清除 KMS 快取...
echo:
call :_taskclear-cache

%nul% reg query "HKLM\%SPPk%\%_wApp%" && (
echo 正在移除 KMS38 保護...
%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':regdel\:.*';. ([scriptblock]::Create($f[1]))"
%nul% reg delete "HKLM\%SPPk%\%_wApp%" /f
%nul% reg query "HKLM\%SPPk%\%_wApp%" && (
call :dk_color %Red% "移除 KMS38 保護失敗。"
) || (
echo 已成功移除 KMS38 保護。
echo 已成功清除 KMS 快取。
)
) || (
echo 已成功清除 KMS 快取。
)
echo:

call :scandat check

if not defined token (
call :dk_color %Red% "找不到 tokens.dat 檔案。"
) else (
echo tokens.dat 檔案: [%token%]
)

set tokenstore=
set badregistry=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v TokenStore %nul6%') do call set "tokenstore=%%b"
if %winbuild% GEQ 9200 if /i not "%tokenstore%"=="%SysPath%\spp\store" if /i not "%tokenstore%"=="%SysPath%\spp\store\2.0" if /i not "%tokenstore%"=="%SysPath%\spp\store_test\2.0" (
set badregistry=1
echo:
call :dk_color %Red% "在 TokenStore 登錄檔中找不到正確路徑 [%tokenstore%]"
)

::  Check sppsvc permissions and apply fixes

if %winbuild% GEQ 9200 if not defined badregistry (
echo:
echo 正在檢查 SPP 權限相關問題...
call :checkperms
if defined permerror (
call :dk_color %Red% "[!permerror!]"
%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':fixsppperms\:.*';. ([scriptblock]::Create($f[1]))" %nul%
call :checkperms
if defined permerror (
call :dk_color %Red% "[!permerror!] [修復失敗]"
) else (
call :dk_color %Green% "[已成功修復]"
)
) else (
echo [未發現錯誤]
)
)

echo:
echo 正在停止 %_slser% 服務...
%psc% Stop-Service %_slser% -force %nul%

set w=
set _sppint=
for %%# in (SppEx%w%tComObj.exe %_slexe%) do (reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ima%w%ge File Execu%w%tion Options\%%#" %nul% && (set _sppint=1))
if defined _sppint (
echo:
echo 正在移除 SPP IFEO 登錄檔機碼...
for %%# in (SppE%w%xtComObj.exe %_slexe%) do (reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ima%w%ge File Execu%w%tion Options\%%#" /f %nul%)
)

if %winbuild% LSS 9200 if not defined _vis (
REM Fix issues caused by Update KB971033 in Windows 7
REM https://support.microsoft.com/en-us/help/4487266
echo:
echo 正在檢查更新 KB971033...
%psc% "if (Get-Hotfix -Id KB971033 -ErrorAction SilentlyContinue) {Exit 3}" %nul%
if !errorlevel!==3 (
echo 已找到，正在解除安裝...
wusa /uninstall /quiet /norestart /kb:971033
) else (
echo [找不到]
)
%psc% Stop-Service sppuinotify -force %nul%
sc config sppuinotify start= disabled
del /f /q %SysPath%\7B296FB0-376B-497e-B012-9C450E1B7327-*.C7483456-A289-439d-8115-601632D005A0 /ah
)

::  Delete registry keys that are not deleted by activation scripts

if not defined _vis (
echo:
echo 正在清理部分授權相關的登錄檔機碼...
%nul% reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "ServiceSessionId" /f
%nul% reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "LicStatusArray" /f
%nul% reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "PolicyValuesArray" /f
%nul% reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "actionlist" /f
%nul% reg delete "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform\data" /f
)

echo:
call :scandat delete
call :scandat check

if defined token (
echo:
call :dk_color %Red% "刪除 .dat 檔案失敗。"
echo:
)

if defined _vis (
%psc% Start-Service %_slser% %nul%
)

echo:
echo 正在重新安裝系統授權...
%psc% "$sls = Get-WmiObject SoftwareLicensingService; $f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':xrm\:.*';. ([scriptblock]::Create($f[1])); ReinstallLicenses" %nul%
if %errorlevel% NEQ 0 %psc% "$sls = Get-WmiObject SoftwareLicensingService; $f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':xrm\:.*';. ([scriptblock]::Create($f[1])); ReinstallLicenses" %nul%
if %errorlevel% EQU 0 (
echo [成功]
) else (
call :dk_color %Red% "[失敗]"
)

call :scandat check

echo:
if not defined token (
call :dk_color %Red% "重建 tokens.dat 檔案失敗。"
) else (
echo tokens.dat 檔案已成功重建。
)

if %winbuild% LSS 9200 if not defined _vis (
sc config sppuinotify start= demand
)

::========================================================================================================================================

::  Rebuild OSPP Tokens

echo:
echo %line%
echo:
call :dk_color %Blue% "正在重建 OSPP 授權 token..."
echo:

sc qc osppsvc %nul% || (
echo 未安裝以 OSPP 為基礎的 Office。
echo 正在略過重建 OSPP token...
goto :repairoffice
)

call :scandatospp check

if not defined token (
call :dk_color %Red% "找不到 tokens.dat 檔案。"
) else (
echo tokens.dat 檔案: [%token%]
)

echo:
echo 正在停止 osppsvc 服務...
%psc% Stop-Service osppsvc -force %nul%

echo:
call :scandatospp delete
call :scandatospp check

if defined token (
echo:
call :dk_color %Red% "刪除 .dat 檔案失敗。"
echo:
)

echo:
echo 正在啟動 osppsvc 服務以產生 tokens.dat...
%psc% Start-Service osppsvc %nul%
call :scandatospp check
if not defined token (
%psc% Stop-Service osppsvc -force %nul%
%psc% Start-Service osppsvc %nul%
timeout /t 3 %nul%
)

call :scandatospp check

echo:
if not defined token (
call :dk_color %Red% "重建 tokens.dat 檔案失敗。"
) else (
echo tokens.dat 檔案已成功重建。
)

::========================================================================================================================================

:repairoffice

echo:
echo %line%
echo:
call :dk_color %Blue% "正在修復 Office 授權..."
echo:

for %%# in (68 86) do (
for %%A in (msi14 msi15 msi16 c2r14 c2r15 c2r16) do (set %%A_%%#=&set %%Arepair%%#=)
)

set _68=HKLM\SOFTWARE\Microsoft\Office
set _86=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office

reg query %_68%\14.0\CVH /f Click2run /k %nul% && (set "c2r14_68=Office 14.0 C2R x86/x64"  & set "c2r14repair68=")
reg query %_86%\14.0\CVH /f Click2run /k %nul% && (set "c2r14_86=Office 14.0 C2R x86"      & set "c2r14repair86=")

for /f "skip=2 tokens=2*" %%a in ('"reg query %_86%\14.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi14_86=Office 14.0 MSI x86"      & call :getrepairsetup msi14repair86 14)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_68%\14.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi14_68=Office 14.0 MSI x86/x64"  & call :getrepairsetup msi14repair68 14)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_86%\15.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi15_86=Office 15.0 MSI x86"      & call :getrepairsetup msi15repair86 15)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_68%\15.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi15_68=Office 15.0 MSI x86/x64"  & call :getrepairsetup msi15repair68 15)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_86%\16.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi16_86=Office 16.0 MSI x86"      & call :getrepairsetup msi16repair86 16)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_68%\16.0\Common\InstallRoot /v Path" %nul6%') do if exist "%%b\*Picker.dll" (set "msi16_68=Office 16.0 MSI x86/x64"  & call :getrepairsetup msi16repair68 16)

for /f "skip=2 tokens=2*" %%a in ('"reg query %_86%\15.0\ClickToRun /v InstallPath" %nul6%') do if exist "%%b\root\Licenses\ProPlus*.xrm-ms" (set "c2r15_86=Office 15.0 C2R x86"      & call :getc2rrepair c2r15repair86 integratedoffice.exe)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_68%\15.0\ClickToRun /v InstallPath" %nul6%') do if exist "%%b\root\Licenses\ProPlus*.xrm-ms" (set "c2r15_68=Office 15.0 C2R x86/x64"  & call :getc2rrepair c2r15repair68 integratedoffice.exe)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_86%\ClickToRun /v InstallPath" %nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms"    (set "c2r16_86=Office 16.0 C2R x86"      & call :getc2r16repair c2r16repair86 OfficeClickToRun.exe)
for /f "skip=2 tokens=2*" %%a in ('"reg query %_68%\ClickToRun /v InstallPath" %nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms"    (set "c2r16_68=Office 16.0 C2R x86/x64"  & call :getc2r16repair c2r16repair68 OfficeClickToRun.exe)

set uwp16=
if %winbuild% GEQ 10240 (
%psc% "Get-AppxPackage -name "Microsoft.Office.Desktop"" | find /i "Office" %nul1% && set uwp16=Office 16.0 UWP
)

set /a counter=0
echo 正在檢查已安裝的 Office 版本...
echo:

for %%# in (
"%msi14_68%"
"%msi14_86%"
"%msi15_68%"
"%msi15_86%"
"%msi16_68%"
"%msi16_86%"
"%c2r14_68%"
"%c2r14_86%"
"%c2r15_68%"
"%c2r15_86%"
"%c2r16_68%"
"%c2r16_86%"
"%uwp16%"
) do (
if not "%%#"=="""" (
set insoff=%%#
set insoff=!insoff:"=!
echo [!insoff!]
set /a counter+=1
)
)

if %counter% GTR 1 (
%eline%
echo 發現多個 Office 版本。
echo 建議只安裝一個版本的 Office。
echo ________________________________________________________________
echo:
)

echo:
if %counter% EQU 0 (
echo 未安裝 Office（2010 及更新版本）。
goto :repairend
) else if not defined c2r16_68 if not defined c2r16_86 (
call :dk_color %_Yellow% "將會出現一個新視窗，請在該視窗中選擇 [快速修復] 選項。"
if defined terminal (
call :dk_color %_Yellow% "按 [0] 繼續..."
choice /c 0 /n
) else (
call :dk_color %_Yellow% "按任意鍵繼續..."
pause %nul1%
)
)

if defined uwp16 (
echo:
echo 正在略過修復 Office 16.0 UWP...
echo:
)

set c2r14=
if defined c2r14_68 set c2r14=1
if defined c2r14_86 set c2r14=1

if defined c2r14 (
echo:
echo 正在略過修復 Office 14.0 C2R...
echo:
)

if defined msi14_68 if exist "%msi14repair68%" echo Running - "%msi14repair68%"                                        & "%msi14repair68%"
if defined msi14_86 if exist "%msi14repair86%" echo Running - "%msi14repair86%"                                        & "%msi14repair86%"
if defined msi15_68 if exist "%msi15repair68%" echo Running - "%msi15repair68%"                                        & "%msi15repair68%"
if defined msi15_86 if exist "%msi15repair86%" echo Running - "%msi15repair86%"                                        & "%msi15repair86%"
if defined msi16_68 if exist "%msi16repair68%" echo Running - "%msi16repair68%"                                        & "%msi16repair68%"
if defined msi16_86 if exist "%msi16repair86%" echo Running - "%msi16repair86%"                                        & "%msi16repair86%"
if defined c2r15_68 if exist "%c2r15repair68%" echo Running - "%c2r15repair68%" REPAIRUI RERUNMODE                     & "%c2r15repair68%" REPAIRUI RERUNMODE
if defined c2r15_86 if exist "%c2r15repair86%" echo Running - "%c2r15repair86%" REPAIRUI RERUNMODE                     & "%c2r15repair86%" REPAIRUI RERUNMODE
if defined c2r16_68 if exist "%c2r16repair68%" echo Running - "%c2r16repair68%" Scenario=Repair RepairType=QuickRepair & "%c2r16repair68%" Scenario=Repair RepairType=QuickRepair
if defined c2r16_86 if exist "%c2r16repair86%" echo Running - "%c2r16repair86%" Scenario=Repair RepairType=QuickRepair & "%c2r16repair86%" Scenario=Repair RepairType=QuickRepair

:repairend

echo:
echo %line%
echo:
echo:
call :dk_color %Green% "已完成"
goto :at_back

:getc2rrepair

for %%# in (X86 X64) do (
if exist "%systemdrive%\Program Files\Microsoft Office 15\Client%%#\%2" (
set "%1=%systemdrive%\Program Files\Microsoft Office 15\Client%%#\%2"
)
)
exit /b

:getc2r16repair

for %%# in (%_68% %_86%) do (
for /f "skip=2 tokens=2*" %%a in ('"reg query %%#\ClickToRun\Configuration /v ClientFolder" %nul6%') do if exist "%%b\%2" (set "%1=%%b\%2")
)
exit /b

:getrepairsetup

set "_common86=%systemdrive%\Program Files (x86)\Common Files\Microsoft Shared\OFFICE%2\Office Setup Controller\setup.exe"
set "_common68=%systemdrive%\Program Files\Common Files\Microsoft Shared\OFFICE%2\Office Setup Controller\setup.exe"

if exist "%_common86%" set "%1=%_common86%"
if exist "%_common68%" set "%1=%_common68%"
exit /b

::========================================================================================================================================

:fixwmi

cls
if not defined terminal mode 98, 34
title  修復 WMI

::  https://techcommunity.microsoft.com/t5/ask-the-performance-team/wmi-repository-corruption-or-not/ba-p/375484

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
%eline%
echo 不建議在 Windows Server 上重建 WMI，正在中止...
goto :at_back
)

echo:
echo 正在檢查 WMI
call :checkwmi

::  Apply basic fix first and check

if defined error (
%psc% Stop-Service Winmgmt -force %nul%
winmgmt /salvagerepository %nul%
call :checkwmi
)

if not defined error (
echo [運作中]
echo 無需套用此選項，正在中止...
goto :at_back
)

call :dk_color %Red% "[沒有回應]"

set _corrupt=
sc start Winmgmt %nul%
if %errorlevel% EQU 1060 set _corrupt=1
sc query Winmgmt %nul% || set _corrupt=1
for %%G in (DependOnService Description DisplayName ErrorControl ImagePath ObjectName Start Type) do if not defined _corrupt (reg query HKLM\SYSTEM\CurrentControlSet\Services\Winmgmt /v %%G %nul% || set _corrupt=1)

echo:
if defined _corrupt (
%eline%
echo Winmgmt 服務已損毀，正在中止...
goto :at_back
)

echo 正在停用 Winmgmt 服務
sc config Winmgmt start= disabled %nul%
if %errorlevel% EQU 0 (
echo [成功]
) else (
call :dk_color %Red% "[失敗] 正在中止..."
sc config Winmgmt start= auto %nul%
goto :at_back
)

echo:
echo 正在停止 Winmgmt 服務
%psc% Stop-Service Winmgmt -force %nul%
%psc% Stop-Service Winmgmt -force %nul%
%psc% Stop-Service Winmgmt -force %nul%
sc query Winmgmt | find /i "STOPPED" %nul% && (
echo [成功]
) || (
call :dk_color %Red% "[失敗]"
call :dk_color %Blue% "建議選擇 [重新啟動] 選項，然後再次套用修復 WMI 選項。"
echo %line%
echo:
choice /C:21 /N /M "> [1] 重新啟動  [2] 還原變更 :"
if !errorlevel!==1 (sc config Winmgmt start= auto %nul%&goto :at_back)
echo:
echo 正在重新啟動...
shutdown -t 5 -r
exit
)

echo:
echo 正在刪除 WMI 存放庫
rmdir /s /q "%SysPath%\wbem\repository\" %nul%
if exist "%SysPath%\wbem\repository\" (
call :dk_color %Red% "[失敗]"
) else (
echo [成功]
)

echo:
echo 正在啟用 Winmgmt 服務
sc config Winmgmt start= auto %nul%
if %errorlevel% EQU 0 (
echo [成功]
) else (
call :dk_color %Red% "[失敗]"
)

call :checkwmi
if not defined error (
echo:
echo 正在檢查 WMI
call :dk_color %Green% "[運作中]"
goto :at_back
)

echo:
echo 正在註冊 .dll 並編譯 .mof 與 .mfl
call :registerobj %nul%

echo:
echo 正在檢查 WMI
call :checkwmi
if defined error (
call :dk_color %Red% "[沒有回應]"
echo:
echo 請執行 [Dism RestoreHealth] 與 [SFC Scannow] 選項，並確認沒有錯誤。
) else (
call :dk_color %Green% "[運作中]"
)

goto :at_back

:registerobj

::  https://eskonr.com/2012/01/how-to-fix-wmi-issues-automatically/

%psc% Stop-Service Winmgmt -force %nul%
cd /d %SysPath%\wbem\
regsvr32 /s %SysPath%\scecli.dll
regsvr32 /s %SysPath%\userenv.dll
mofcomp cimwin32.mof
mofcomp cimwin32.mfl
mofcomp rsop.mof
mofcomp rsop.mfl
for /f %%s in ('dir /b /s *.dll') do regsvr32 /s %%s
for /f %%s in ('dir /b *.mof') do mofcomp %%s
for /f %%s in ('dir /b *.mfl') do mofcomp %%s

winmgmt /salvagerepository
winmgmt /resetrepository
exit /b

:checkwmi

::  https://learn.microsoft.com/en-us/windows/win32/wmisdk/wmi-error-constants

set error=
%psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" %nul2% | find /i "computersystem" %nul1%
if %errorlevel% NEQ 0 (set error=1& exit /b)
winmgmt /verifyrepository %nul%
if %errorlevel% NEQ 0 (set error=1& exit /b)

%psc% "try { $null=([WMISEARCHER]'SELECT * FROM SoftwareLicensingService').Get().Version; exit 0 } catch { exit $_.Exception.InnerException.HResult }" %nul%
cmd /c exit /b %errorlevel%
echo "0x%=ExitCode%" | findstr /i "0x800410 0x800440 0x80131501" %nul1%
if %errorlevel% EQU 0 set error=1
exit /b

::========================================================================================================================================

:at_back

echo:
echo %line%
echo:
if defined terminal (
call :dk_color %_Yellow% "按 [0] 鍵以%_exitmsg%..."
choice /c 0 /n
) else (
call :dk_color %_Yellow% "按任意鍵以%_exitmsg%..."
pause %nul1%
)
goto :at_menu

::========================================================================================================================================

:compresslog

::  https://stackoverflow.com/a/46268232

set "ddf="%SystemRoot%\Temp\%Random%%Random%%Random%%Random%""
%nul% del /q /f %ddf%
echo/.New Cabinet>%ddf%
echo/.set Cabinet=ON>>%ddf%
echo/.set CabinetFileCountThreshold=0;>>%ddf%
echo/.set Compress=ON>>%ddf%
echo/.set CompressionType=LZX>>%ddf%
echo/.set CompressionLevel=7;>>%ddf%
echo/.set CompressionMemory=21;>>%ddf%
echo/.set FolderFileCountThreshold=0;>>%ddf%
echo/.set FolderSizeThreshold=0;>>%ddf%
echo/.set GenerateInf=OFF>>%ddf%
echo/.set InfFileName=nul>>%ddf%
echo/.set MaxCabinetSize=0;>>%ddf%
echo/.set MaxDiskFileCount=0;>>%ddf%
echo/.set MaxDiskSize=0;>>%ddf%
echo/.set MaxErrors=1;>>%ddf%
echo/.set RptFileName=nul>>%ddf%
echo/.set UniqueFiles=ON>>%ddf%
for /f "tokens=* delims=" %%D in ('dir /a:-D/b/s "%SystemRoot%\logs\%1"') do (
 echo/"%%~fD"  /inf=no;>>%ddf%
)
makecab /F %ddf% /D DiskDirectory1="" /D CabinetNameTemplate="!desktop!\%2_%_time%.cab"
del /q /f %ddf%
exit /b

::========================================================================================================================================

:checkperms

::  This code checks if SPP has permission access to tokens folder and required registry keys. Incorrect permissions are often set by gaming spoofers.

set permerror=
if not exist "%tokenstore%\" set "permerror=Error Found In Token Folder"

if defined ps32onArm exit /b

for %%# in (
"%tokenstore%+FullControl"
"HKLM:\SYSTEM\WPA+QueryValues, EnumerateSubKeys, WriteKey"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform+SetValue"
) do for /f "tokens=1,2 delims=+" %%A in (%%#) do if not defined permerror (
%psc% "$acl = (Get-Acl '%%A' | fl | Out-String); if (-not ($acl -match 'NT SERVICE\\sppsvc Allow  %%B') -or ($acl -match 'NT SERVICE\\sppsvc Deny')) {Exit 2}" %nul%
if !errorlevel!==2 (
if "%%A"=="%tokenstore%" (
set "permerror=Error Found In Token Folder"
) else (
set "permerror=Error Found In SPP Registries"
)
)
)

REM  https://learn.microsoft.com/en-us/office/troubleshoot/activation/license-issue-when-start-office-application

if not defined permerror (
reg query "HKU\S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion" %nul% && (
set "pol=HKU\S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\Policies"
reg query "!pol!" %nul% || reg add "!pol!" %nul%
%psc% "$netServ = (New-Object Security.Principal.SecurityIdentifier('S-1-5-20')).Translate([Security.Principal.NTAccount]).Value; $aclString = Get-Acl 'Registry::!pol!' | Format-List | Out-String; if (-not ($aclString.Contains($netServ + ' Allow  FullControl') -or $aclString.Contains('NT SERVICE\sppsvc Allow  FullControl')) -or ($aclString.Contains('Deny'))) {Exit 3}" %nul%
if !errorlevel!==3 set "permerror=Error Found In S-1-5-20 SPP"
)
)
exit /b

::========================================================================================================================================

::  Clean existing K-M-S cache from the registry

:_taskclear-cache

set w=
for %%# in (SppE%w%xtComObj.exe sppsvc.exe SLsvc.exe) do (
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ima%w%ge File Execu%w%tion Options\%%#" /f %nul%
)

set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"

if %winbuild% LSS 7600 (
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SL" %nul% && (
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SL"
)
)
if not defined SPPk (
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
)

set "slp=SoftwareLicensingProduct"
set "ospp=OfficeSoftwareProtectionProduct"

set "_wApp=55c92734-d682-4d71-983e-d6ec3f16059f"
set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
set "_oA14=59a52881-a989-479d-af46-f275c6370663"

%nul% reg delete "HKLM\%SPPk%" /f /v KeyManagementServiceName
%nul% reg delete "HKLM\%SPPk%" /f /v KeyManagementServiceName /reg:32
%nul% reg delete "HKLM\%SPPk%" /f /v KeyManagementServicePort
%nul% reg delete "HKLM\%SPPk%" /f /v KeyManagementServicePort /reg:32
%nul% reg delete "HKLM\%SPPk%" /f /v DisableDnsPublishing
%nul% reg delete "HKLM\%SPPk%" /f /v DisableKeyManagementServiceHostCaching
%nul% reg delete "HKLM\%SPPk%\%_wApp%" /f
if %winbuild% GEQ 9200 (
%nul% reg delete "HKLM\%SPPk%\%_oApp%" /f
%nul% reg delete "HKLM\%SPPk%\%_oApp%" /f /reg:32
)
if %winbuild% GEQ 9600 (
%nul% reg delete "HKU\S-1-5-20\%SPPk%\%_wApp%" /f
%nul% reg delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f
)
%nul% reg delete "HKLM\%OPPk%" /f /v KeyManagementServiceName
%nul% reg delete "HKLM\%OPPk%" /f /v KeyManagementServicePort
%nul% reg delete "HKLM\%OPPk%" /f /v DisableDnsPublishing
%nul% reg delete "HKLM\%OPPk%" /f /v DisableKeyManagementServiceHostCaching
%nul% reg delete "HKLM\%OPPk%\%_oA14%" /f
%nul% reg delete "HKLM\%OPPk%\%_oApp%" /f

exit /b

::========================================================================================================================================

::  Fix SPP related registry and folder permissions

:fixsppperms:
# Fix perms for Token Folder

if ($env:permerror -eq 'Error Found In Token Folder') {
    New-Item -Path $env:tokenstore -ItemType Directory -Force
    $sddl = 'O:BAG:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICIIO;GR;;;BU)(A;;FR;;;BU)(A;OICI;FA;;;S-1-5-80-123231216-2592883651-3715271367-3753151631-4175906628)'
    $AclObject = New-Object System.Security.AccessControl.DirectorySecurity
    $AclObject.SetSecurityDescriptorSddlForm($sddl)
    Set-Acl -Path $env:tokenstore -AclObject $AclObject
    exit
}

# Fix perms for SPP registries

if ($env:permerror -eq 'Error Found In SPP Registries') {
    $acl = Get-Acl 'HKLM:\SYSTEM\WPA'
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ('NT Service\sppsvc', 'QueryValues, EnumerateSubKeys, WriteKey', 'ContainerInherit, ObjectInherit', 'None', 'Allow')
    $acl.ResetAccessRule($rule)
    $acl.SetAccessRule($rule)
    Set-Acl -Path 'HKLM:\SYSTEM\WPA' -AclObject $acl
	
    $acl = Get-Acl 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform'
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ('NT Service\sppsvc', 'SetValue', 'ContainerInherit, ObjectInherit', 'None', 'Allow')
    $acl.ResetAccessRule($rule)
    $acl.SetAccessRule($rule)
    Set-Acl -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform' -AclObject $acl
    exit
}

# Fix perms for SPP in HKU\S-1-5-20
# https://learn.microsoft.com/en-us/office/troubleshoot/activation/license-issue-when-start-office-application

if ($env:permerror -ne 'Error Found In S-1-5-20 SPP') {
    exit
}
if (-not (Test-Path 'Registry::HKU\S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform')) {
    exit
}

# https://stackoverflow.com/a/35843420

function Take-Permissions {
    param($rootKey, $key, [System.Security.Principal.SecurityIdentifier]$sid = 'S-1-5-32-545', $recurse = $true)
    
    switch -regex ($rootKey) {
        'HKCU|HKEY_CURRENT_USER' { $rootKey = 'CurrentUser' }
        'HKLM|HKEY_LOCAL_MACHINE' { $rootKey = 'LocalMachine' }
        'HKCR|HKEY_CLASSES_ROOT' { $rootKey = 'ClassesRoot' }
        'HKCC|HKEY_CURRENT_CONFIG' { $rootKey = 'CurrentConfig' }
        'HKU|HKEY_USERS' { $rootKey = 'Users' }
    }

    ### Step 1 - escalate current process's privilege
    # get SeTakeOwnership, SeBackup and SeRestore privileges before executes next lines, script needs Admin privilege
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
    $TypeBuilder = $ModuleBuilder.DefineType(0)
    $TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
    9, 17, 18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

    function Take-KeyPermissions {
        param($rootKey, $key, $sid, $recurse, $recurseLevel = 0)

        ### Step 2 - get ownerships of key - it works only for current key
        $regKey = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($sid)
        $regKey.SetAccessControl($acl)

        ### Step 3 - enable inheritance of permissions (not ownership) for current key from parent
        $acl.SetAccessRuleProtection($false, $false)
        $regKey.SetAccessControl($acl)

        ### Step 4 - only for top-level key, change permissions for current key and propagate it for subkeys
        # to enable propagations for subkeys, it needs to execute Steps 2-3 for each subkey (Step 5)
        if ($recurseLevel -eq 0) {
            $regKey = $regKey.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($sid, 'FullControl', 'ContainerInherit', 'None', 'Allow')
            $acl.ResetAccessRule($rule)
            $regKey.SetAccessControl($acl)
        }

        ### Step 5 - recursively repeat steps 2-5 for subkeys
        if ($recurse) {
            foreach ($subKey in $regKey.OpenSubKey('').GetSubKeyNames()) {
                Take-KeyPermissions $rootKey ($key + '\' + $subKey) $sid $recurse ($recurseLevel + 1)
            }
        }
    }

    Take-KeyPermissions $rootKey $key $sid $recurse
}

Take-Permissions "Users" "S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "S-1-5-20"
:fixsppperms:

::========================================================================================================================================

::  Install License files using Powershell/WMI instead of slmgr.vbs

:xrm:
function InstallLicenseFile($Lsc) {
    try {
        $null = $sls.InstallLicense([IO.File]::ReadAllText($Lsc))
    } catch {
        $host.SetShouldExit($_.Exception.HResult)
    }
}
function InstallLicenseArr($Str) {
    $a = $Str -split ';'
    ForEach ($x in $a) {InstallLicenseFile "$x"}
}
function InstallLicenseDir($Loc) {
	Get-ChildItem $Loc -Recurse -Filter *.xrm-ms | ForEach-Object {InstallLicenseFile $_.FullName}
}
function ReinstallLicenses() {
	$Paths = @("$env:SysPath\oem", "$env:SysPath\licensing", "$env:SysPath\spp\tokens")
	foreach ($Path in $Paths) {
    if (Test-Path $Path) { InstallLicenseDir "$Path" }
	}
}
:xrm:

::========================================================================================================================================

:scandat

set token=
for %%# in (
%SysPath%\spp\store_test\2.0\
%SysPath%\spp\store\
%SysPath%\spp\store\2.0\
%Systemdrive%\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\
%Systemdrive%\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareLicensing\
) do (

if %1==check (
if exist %%#tokens.dat set token=%%#tokens.dat
)

if %1==delete (
if exist %%# (
%nul% dir /a-d /s "%%#*.dat" && (
attrib -r -s -h "%%#*.dat" /S
del /S /F /Q "%%#*.dat"
)
)
)
)
exit /b

:scandatospp

set token=
for %%# in (
%ProgramData%\Microsoft\OfficeSoftwareProtectionPlatform\
) do (

if %1==check (
if exist %%#tokens.dat set token=%%#tokens.dat
)

if %1==delete (
if exist %%# (
%nul% dir /a-d /s "%%#*.dat" && (
attrib -r -s -h "%%#*.dat" /S
del /S /F /Q "%%#*.dat"
)
)
)
)
exit /b

::========================================================================================================================================

:regownstart

%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':regown\:.*';. ([scriptblock]::Create($f[1]));"
exit /b

::  Below code takes ownership of a volatile registry key and deletes it
::  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState

:regown:
$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
$TypeBuilder = $ModuleBuilder.DefineType(0)

$TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
$TypeBuilder.CreateType()::RtlAdjustPrivilege(9, $true, $false, [ref]$false) | Out-Null

$SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
$IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
$Admin = New-Object System.Security.Principal.NTAccount($IDN)

$path = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState'
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64').OpenSubKey($path, 'ReadWriteSubTree', 'takeownership')

$acl = $key.GetAccessControl()
$acl.SetOwner($Admin)
$key.SetAccessControl($acl)

$rule = New-Object System.Security.AccessControl.RegistryAccessRule($Admin,"FullControl","Allow")
$acl.SetAccessRule($rule)
$key.SetAccessControl($acl)
:regown:

::========================================================================================================================================

::  This code runs to undo below registry key KMS38 protection
::  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\55c92734-d682-4d71-983e-d6ec3f16059f

::  This option is not used in KMS38 anymore, it's here only to remove previous versions protection.

:regdel:
param (
    [switch]$protect
)

$SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
$Admin = ($SID.Translate([System.Security.Principal.NTAccount])).Value

if($protect) {
$ruleArgs = @("$Admin", "Delete, SetValue", "ContainerInherit", "None", "Deny")
} else {
$ruleArgs = @("$Admin", "FullControl", "Allow")
}

$path = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\55c92734-d682-4d71-983e-d6ec3f16059f'
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64').OpenSubKey($path, 'ReadWriteSubTree', 'ChangePermissions')
$acl = $key.GetAccessControl()

$rule = [System.Security.AccessControl.RegistryAccessRule]::new.Invoke($ruleArgs)
$acl.ResetAccessRule($rule)
$key.SetAccessControl($acl)
:regdel:

::========================================================================================================================================

:dk_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else if exist %ps% (
%psc% write-host -back '%1' -fore '%2' '%3'
) else if not exist %ps% (
echo %~3
)
exit /b

:dk_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else if exist %ps% (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
) else if not exist %ps% (
echo %~3 %~6
)
exit /b

::========================================================================================================================================

:dk_done

echo:
if %_unattended%==1 timeout /t 2 & exit /b

if defined fixes (
call :dk_color %White% "請遵循上方所有藍色文字的指示。   "
call :dk_color2 %Blue% "按 [1] 開啟支援網頁 " %Gray% " 按 [0] 返回"
choice /C:10 /N
if !errorlevel!==2 exit /b
if !errorlevel!==1 (start %selfgit% & start %github% & for %%# in (%fixes%) do (start %%#))
)

if defined terminal (
call :dk_color %_Yellow% "按 [0] 鍵以%_exitmsg%..."
choice /c 0 /n
) else (
call :dk_color %_Yellow% "按任意鍵以%_exitmsg%..."
pause %nul1%
)

exit /b

::========================================================================================================================================

::  Set variables

:dk_setvar

set ps=%SysPath%\WindowsPowerShell\v1.0\powershell.exe
set psc=%ps% -nop -c
set winbuild=1
for /f "tokens=2 delims=[]" %%G in ('ver') do for /f "tokens=2,3,4 delims=. " %%H in ("%%~G") do set "winbuild=%%J"

set _slexe=sppsvc.exe& set _slser=sppsvc
if %winbuild% LEQ 6300 (set _slexe=SLsvc.exe& set _slser=SLsvc)
if %winbuild% LSS 7600 if exist "%SysPath%\SLsvc.exe" (set _slexe=SLsvc.exe& set _slser=SLsvc)
if %_slexe%==SLsvc.exe set _vis=1

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

echo "%PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%" | find /i "ARM64" %nul1% && (if %winbuild% LSS 21277 set ps32onArm=1)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set    "Blue="44;97m""
set   "White="107;91m""
set    "_Red="40;91m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set   "White="White" "Red""
set    "_Red="Black" "Red""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :dk_color %Red% "==== ERROR ====" &echo:"
if %~z0 GEQ 200000 (
set "_exitmsg=返回"
set "_fixmsg=請回到主選單，選擇疑難排解，然後執行修復授權選項。"
) else (
set "_exitmsg=離開"
set "_fixmsg=請在 MAS 資料夾執行疑難排解腳本，並選擇修復授權選項。"
)
exit /b

::========================================================================================================================================
:: Leave empty line below
