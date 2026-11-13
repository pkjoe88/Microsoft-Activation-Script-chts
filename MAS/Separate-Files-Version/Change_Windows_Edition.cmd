@set masver=3.14
@echo off



::============================================================================
::
::   Homepage: m{}assgrave{dot}dev
::
::============================================================================



::  To stage current edition while changing edition with CBS Upgrade Method, change 0 to 1 in below line
set _stg=0



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
title  變更 Windows 版本 %masver%

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
set "line=echo ___________________________________________________________________________________________"

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

if %winbuild% LSS 7600 (
%eline%
echo 偵測到不支援的作業系統版本 [%winbuild%]。
echo 此選項僅支援 Windows 7/8/8.1/10/11 與對應的 Server 版本。
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

cls
if not defined terminal mode 98, 30
title  變更 Windows 版本 %masver%

echo:
echo 正在初始化...
echo:

for %%# in (
sppsvc.exe
dism.exe
) do (
if not exist %SysPath%\%%# (
%eline%
echo 檔案 [%SysPath%\%%#] 遺失，正在中止...
call :dk_color %Blue% "請回到主選單，選擇疑難排解，然後執行 DISM 還原與 SFC 掃描選項。"
call :dk_color %Blue% "完成後重新啟動系統，再重新嘗試啟用。"
set fixes=%fixes% %mas%in-place_repair_upgrade
call :dk_color2 %Blue% "如果仍出現相同錯誤，請這樣做 - " %_Yellow% " %mas%in-place_repair_upgrade"
goto dk_done
)
)

::========================================================================================================================================

set spp=SoftwareLicensingProduct
set sps=SoftwareLicensingService

call :dk_reflection
call :dk_ckeckwmic
call :dk_sppissue

for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if not "%%j"=="" (
set fullbuild=%%i.%%j
) else (
for /f "tokens=3" %%G in ('"reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v UBR" %nul6%') do if not errorlevel 1 set /a "UBR=%%G"
for /f "skip=2 tokens=3,4 delims=. " %%G in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx') do (
if defined UBR (set "fullbuild=%%G.!UBR!") else (set "fullbuild=%%G.%%H")
)
)

::========================================================================================================================================

::  Check Activation IDs

call :dk_actids 55c92734-d682-4d71-983e-d6ec3f16059f
if not defined allapps (
%eline%
echo 找不到啟用識別碼。正在中止...
call :dk_color %Blue% "若要修復此問題，請從主選單啟用 Windows。"
goto dk_done
)

::========================================================================================================================================

::  Check Windows Edition and branch

set osedition=
set dismnotworking=

for /f "tokens=3 delims=: " %%a in ('DISM /English /Online /Get-CurrentEdition %nul6% ^| find /i "Current Edition :"') do set "osedition=%%a"
if not defined osedition set dismnotworking=1

if %_wmic% EQU 1 set "chkedi=for /f "tokens=2 delims==" %%a in ('"wmic path %spp% where (ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseDependsOn is NULL AND PartialProductKey IS NOT NULL) get LicenseFamily /VALUE" %nul6%')"
if %_wmic% EQU 0 set "chkedi=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT LicenseFamily FROM %spp% WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND LicenseDependsOn is NULL AND PartialProductKey IS NOT NULL').Get()).LicenseFamily ^| %% {echo ('LicenseFamily='+$_)}" %nul6%')"
if not defined osedition %chkedi% do if not errorlevel 1 (call set "osedition=%%a")

if not defined osedition (
%eline%
echo 無法偵測作業系統版本，正在中止...
call :dk_color %Blue% "若要修復此問題，請從主選單啟用 Windows。"
goto dk_done
)

for /f "skip=2 tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID %nul6%') do set "regedition=%%a"
if /i not "%osedition%"=="%regedition%" (
set "showeditionerror=call :dk_color %_Yellow% "[%osedition%] [Reg-%regedition%].""
)

set branch=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildBranch %nul6%') do set "branch=%%b"

::========================================================================================================================================

::  Get target editions list

set _target=
set _dtarget=
set _ptarget=
set _ntarget=
set _wtarget=

if %winbuild% GEQ 10240 for /f "tokens=4" %%a in ('dism /online /english /Get-TargetEditions ^| findstr /i /c:"Target Edition : "') do (if defined _dtarget (set "_dtarget= !_dtarget! %%a ") else (set "_dtarget= %%a "))
if %winbuild% LSS 10240 for /f "tokens=4" %%a in ('%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':cbsxml\:.*';. ([scriptblock]::Create($f[1])) -GetTargetEditions;" ^| findstr /i /c:"Target Edition : "') do (if defined _ptarget (set "_ptarget= !_ptarget! %%a ") else (set "_ptarget= %%a "))

if %winbuild% GEQ 10240 if not exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
if %winbuild% GEQ 17063 call :ced_edilist
if /i "%osedition:~0,4%"=="Core" set _pro=Professional
if /i "%osedition%"=="CoreN" set _pro=ProfessionalN
set "_dtarget= %_dtarget% !_wtarget! !_pro! "
)

::========================================================================================================================================

for %%# in (CloudEdition CloudEditionN ServerRdsh) do if /i %osedition%==%%# (
cls
echo:
call :dk_color %Red% "==== 注意 ===="
echo:
echo [EditionID:%osedition% ^| %fullbuild%]
echo:
echo 變更此版本可能無法移除「%osedition%」專屬的功能。
echo:
call :dk_color %_Yellow% "按 [7] 仍要繼續..."
choice /c 7 /n
cls
)

for %%# in ( %_dtarget% %_ptarget% ) do if /i not "%%#"=="%osedition%" (
echo "!_target!" | find /i " %%# " %nul1% || set "_target= !_target! %%# "
)

if defined _target (
for %%# in (%_target%) do (
echo %%# | findstr /i "CountrySpecific CloudEdition" %nul% || (set "_ntarget=!_ntarget! %%#")
)
)

if not defined _ntarget (
%line%
echo:
if defined dismnotworking call :dk_color %Red% "DISM.exe is not working."
call :dk_color %Gray% "找不到目標版本。"
echo 目前的版本 [%osedition% ^| %winbuild%] 無法變更為任何其他版本。
%line%
goto dk_done
)

::========================================================================================================================================

:cedmenu2

cls
if not defined terminal mode 98, 30
set inpt=
set counter=0
set verified=0
set targetedition=

%line%
echo:
call :dk_color %Gray% "您可以將版本 [%osedition%] [%fullbuild%] 變更為下列其中之一。"
%showeditionerror%
if defined dismnotworking (
call :dk_color %_Yellow% "注意 - DISM.exe 無法運作。"
if /i "%osedition:~0,4%"=="Core" call :dk_color %_Yellow% "     - You will see more edition options to choose once its changed to Pro."
)
%line%
echo:

for %%A in (%_ntarget%) do (
set /a counter+=1
if /i %%A==IoTEnterprise (
echo [!counter!]  %%A [GAC，非 LTSC]
) else (
echo [!counter!]  %%A
)
set targetedition!counter!=%%A
)

%line%
echo:
echo [0]  %_exitmsg%
echo:
call :dk_color %_Green% "請以鍵盤輸入選項數字，並按 Enter 確認："
set /p inpt=
if "%inpt%"=="" goto cedmenu2
if "%inpt%"=="0" exit /b
for /l %%i in (1,1,%counter%) do (if "%inpt%"=="%%i" set verified=1)
set targetedition=!targetedition%inpt%!
if %verified%==0 goto cedmenu2

::========================================================================================================================================

if %winbuild% LSS 10240 goto :cbsmethod
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" goto :ced_change_server

cls
if not defined terminal mode con cols=105 lines=32

if /i "%targetedition%"=="ServerRdsh" (
echo:
call :dk_color %Red% "==== 注意 ===="
echo:
echo 當版本變更為「%targetedition%」後，
echo 系統之後可能無法正常變更版本。
echo:
echo [1] 仍要繼續
echo [0] 返回
echo:
call :dk_color %_Green% "請以鍵盤選擇選單選項 [1,0]："
choice /C:10 /N
if !errorlevel!==2 goto cedmenu2
if !errorlevel!==1 rem
)

cls
set key=
set _chan=
set _dismapi=0

::  Check if DISM API or slmgr.vbs is required for edition upgrade

if not exist "%SysPath%\spp\tokens\skus\%targetedition%\%targetedition%*.xrm-ms" (
echo %_wtarget% | find /i " %targetedition% " || (
set _dismapi=1
)
)

set "keyflow=Retail OEM:NONSLP OEM:DM Volume:MAK Volume:GVLK PGS:TB Retail:TB:Eval"

call :ced_targetSKU %targetedition%
if defined targetSKU call :ced_windowskey
if defined key if defined pkeychannel set _chan=%pkeychannel%
if not defined key call :changeeditiondata
if not defined key if %_dismapi%==1 if /i "%targetedition%"=="Professional" (
set key=VK7JG-NPHTM-C97JM-9MPGT-3V66T
set _chan=Retail
)

if not defined key (
%eline%
echo [%targetedition% ^| %winbuild%]
echo 無法從 pkeyhelper.dll 取得產品金鑰。
set fixes=%fixes% %mas%troubleshoot
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%troubleshoot"
goto dk_done
)

::========================================================================================================================================

::  Changing from Core to Non-Core & Changing editions in Windows build older than 17134 requires "changepk /productkey" or DISM Api method and restart
::  In other cases, editions can be changed instantly with "slmgr /ipk"

if %_dismapi%==1 (
if not defined terminal mode con cols=105 lines=40
call :ced_rebootflag
if defined rebootreq goto dk_done
)

cls
%line%
echo:
%showeditionerror%
if defined dismnotworking call :dk_color %_Yellow% "DISM.exe is not working."
echo 正在將目前版本 [%osedition%] %fullbuild% 變更為 [%targetedition%]...
echo:

if %_dismapi%==1 (
call :dk_color %Green% "注意事項 -"
echo:
echo  - 繼續之前請先儲存您的工作，系統將會自動重新啟動。
echo:
echo  - 版本變更後，您需要使用 HWID 選項來啟用。
%line%
echo:
choice /C:21 /N /M "[1] 繼續 [2] %_exitmsg% : "
if !errorlevel!==1 exit /b
)

::========================================================================================================================================

if %_dismapi%==0 (
echo 正在安裝 %_chan% 金鑰 [%key%]
echo:
if %_wmic% EQU 1 wmic path %sps% where __CLASS='%sps%' call InstallProductKey ProductKey="%key%" %nul%
if %_wmic% EQU 0 %psc% "try { $null=(([WMISEARCHER]'SELECT Version FROM %sps%').Get()).InstallProductKey('%key%'); exit 0 } catch { exit $_.Exception.InnerException.HResult }" %nul%
set keyerror=!errorlevel!
cmd /c exit /b !keyerror!
if !keyerror! NEQ 0 set "keyerror=[0x!=ExitCode!]"

if !keyerror! EQU 0 (
call :dk_refresh
call :dk_color %Green% "[成功]"
echo:
call :dk_color %Gray% "需要重新開機才能完整變更版本。"
) else (
call :dk_color %Red% "[未成功] [錯誤碼: !keyerror!]"
set fixes=%fixes% %mas%troubleshoot
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%troubleshoot"
)
)

if %_dismapi%==1 (
echo:
echo 正在使用 %_chan% 金鑰 %key% 套用 DISM API 方式。請稍候...
echo:

call :ced_prep
if defined preperror goto dk_done

%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':dismapi\:.*';. ([scriptblock]::Create($f[1])) %targetedition% %key%"
call :ced_postprep
)
%line%

goto dk_done

::========================================================================================================================================

:cbsmethod

cls
if not defined terminal (
mode con cols=105 lines=32
%psc% "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=200;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}" %nul%
)

call :ced_rebootflag
if defined rebootreq goto dk_done

echo:
%showeditionerror%
if defined dismnotworking call :dk_color %_Yellow% "Note - DISM.exe is not working."
echo 正在將目前版本 [%osedition%] %fullbuild% 變更為 [%targetedition%]...
echo:
call :dk_color %Blue% "重要 - 繼續之前請先儲存您的工作，系統將會自動重新啟動。"
echo:
choice /C:01 /N /M "[1] 繼續 [0] %_exitmsg% : "
if %errorlevel%==1 exit /b

echo:
echo 正在初始化...
echo:

call :ced_prep
if defined preperror goto dk_done

if %_stg%==0 (set stage=) else (set stage=-StageCurrent)
%psc% "$f=[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950)) -split ':cbsxml\:.*';. ([scriptblock]::Create($f[1])) -SetEdition %targetedition% %stage%"
call :ced_postprep
%line%

goto dk_done

::========================================================================================================================================

:ced_change_server

cls
if not defined terminal (
mode con cols=105 lines=32
%psc% "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=200;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}" %nul%
)

set key=
set _chan=
set "keyflow=Volume:GVLK Retail Volume:MAK OEM:NONSLP OEM:DM PGS:TB Retail:TB:Eval"

call :ced_targetSKU %targetedition%
if defined targetSKU call :ced_windowskey
if defined key if defined pkeychannel set _chan=%pkeychannel%
if not defined key call :changeeditiondata

if not defined key (
%eline%
echo [%targetedition% ^| %winbuild%]
echo 無法從 pkeyhelper.dll 取得產品金鑰。
set fixes=%fixes% %mas%troubleshoot
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%troubleshoot"
goto dk_done
)

call :ced_rebootflag
if defined rebootreq goto dk_done

cls
echo:
%showeditionerror%
if defined dismnotworking call :dk_color %_Yellow% "Note - DISM.exe is not working."
echo 正在將目前版本 [%osedition%] %fullbuild% 變更為 [%targetedition%]...
echo:

call :ced_prep
if defined preperror goto dk_done

echo 正在使用 %_chan% 金鑰套用命令...
echo DISM /online /Set-Edition:%targetedition% /ProductKey:%key% /AcceptEula
DISM /online /Set-Edition:%targetedition% /ProductKey:%key% /AcceptEula

call :ced_postprep
%line%

goto dk_done

::========================================================================================================================================

:ced_prep

set _time=
set preperror=

for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

%psc% Stop-Service TrustedInstaller -force %nul%

sc query TrustedInstaller | find /i "RUNNING" %nul% && (
%eline%
echo 無法停止 TrustedInstaller 服務。
echo 請使用「重新啟動」選項重新開機，然後再試一次。
set preperror=1
exit /b
)

copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\backup_cbs_%_time%.log" %nul%
copy /y /b "%SystemRoot%\logs\DISM\dism.log" "%SystemRoot%\logs\DISM\backup_dism_%_time%.log" %nul%

del /f /q "%SystemRoot%\logs\cbs\cbs.log" %nul%
del /f /q "%SystemRoot%\logs\DISM\dism.log" %nul%

:: Initiate this to appear in fresh logs

dism /online /english /Get-CurrentEdition %nul%
dism /online /english /Get-TargetEditions %nul%
exit /b

::========================================================================================================================================

:ced_postprep

timeout /t 5 %nul1%
copy /y /b "%SystemRoot%\logs\cbs\cbs.log" "%SystemRoot%\logs\cbs\cbs_%_time%.log" %nul%
copy /y /b "%SystemRoot%\logs\DISM\dism.log" "%SystemRoot%\logs\DISM\dism_%_time%.log" %nul%

if not exist "!desktop!\ChangeEdition_Logs\" md "!desktop!\ChangeEdition_Logs\" %nul%
call :compresslog cbs\cbs_%_time%.log ChangeEdition_Logs\CBS %nul%
call :compresslog DISM\dism_%_time%.log ChangeEdition_Logs\DISM %nul%

echo:
if %winbuild% GEQ 9200 %psc% "if ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3).State -eq 'Enabled') {Write-Host 'Checking .NET Framework 3.5 Status - Enabled'}"
echo 記錄檔已複製到桌面上的 ChangeEdition_Logs 資料夾。
echo:
call :dk_color %Blue% "如果出現錯誤，請先重新啟動系統再試一次。"
echo:
set fixes=%fixes% %mas%change_edition_issues
call :dk_color2 %Blue% "請查看此網頁尋求協助 - " %_Yellow% " %mas%change_edition_issues"
exit /b

:compresslog

::  https://stackoverflow.com/a/46268232

for /f %%G in ('%psc% "[Guid]::NewGuid().Guid"') do set "randguid=%%G"
set "ddf="%SystemRoot%\Temp\%Random%%randguid%""
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

::  Refresh license status

:dk_refresh

if %_wmic% EQU 1 wmic path %sps% where __CLASS='%sps%' call RefreshLicenseStatus %nul%
if %_wmic% EQU 0 %psc% "$null=(([WMICLASS]'%sps%').GetInstances()).RefreshLicenseStatus()" %nul%
exit /b

::  Get all products Activation IDs

:dk_actids

set allapps=
if %_wmic% EQU 1 set "chkapp=for /f "tokens=2 delims==" %%a in ('"wmic path %spp% where (ApplicationID='%1') get ID /VALUE" %nul6%')"
if %_wmic% EQU 0 set "chkapp=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT ID FROM %spp% WHERE ApplicationID=''%1''').Get()).ID ^| %% {echo ('ID='+$_)}" %nul6%')"
%chkapp% do (if defined allapps (call set "allapps=!allapps! %%a") else (call set "allapps=%%a"))
exit /b

::  Get Edition list

:ced_edilist

if %_wmic% EQU 1 set "chkedi=for /f "tokens=2 delims==" %%a in ('"wmic path %spp% where (ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseDependsOn is NULL) get LicenseFamily /VALUE" %nul6%')"
if %_wmic% EQU 0 set "chkedi=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT LicenseFamily FROM %spp% WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND LicenseDependsOn is NULL').Get()).LicenseFamily ^| %% {echo ('LicenseFamily='+$_)}" %nul6%')"
%chkedi% do call set "_wtarget= !_wtarget! %%a "
exit /b

::  Check wmic.exe

:dk_ckeckwmic

if %winbuild% LSS 9200 (set _wmic=1&exit /b)
set _wmic=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" %nul2% | find /i "computersystem" %nul1% && set _wmic=1
)
exit /b

::  Show info for potential script stuck scenario

:dk_sppissue

sc start %_slser% %nul%
set spperror=%errorlevel%

if %spperror% NEQ 1056 if %spperror% NEQ 0 (
%eline%
echo sc start %_slser% [錯誤碼: %spperror%]
if %spperror% EQU 1053 (
call :dk_color %Blue% "請使用「重新啟動」選項重新開機，然後再試一次。"
call :dk_color %Blue% "如果仍然無效，請回到主選單，選擇疑難排解，然後執行修復 WPA 登錄檔選項。"
)
)

echo:
%psc% "$job = Start-Job { (Get-WmiObject -Query 'SELECT * FROM %sps%').Version }; if (-not (Wait-Job $job -Timeout 30)) {write-host '%_slser% is not working correctly. Check this webpage for help - %mas%troubleshoot'}"
exit /b

::  Common lines used in PowerShell reflection code

:dk_reflection

set ref=$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1);
set ref=%ref% $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False);
set ref=%ref% $TypeBuilder = $ModuleBuilder.DefineType(0);
exit /b

::========================================================================================================================================

::  Check pending reboot flags

:ced_rebootflag

set rebootreq=
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" %nul% && set rebootreq=1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" %nul% && set rebootreq=1

if defined rebootreq (
%eline%
echo 發現擱置中的重新開機旗標。
echo:
echo 請確認 Windows 已完整更新，重新啟動系統後再試一次。
)
exit /b

::========================================================================================================================================

::  Get Product Key from pkeyhelper.dll for future new editions
::  It works on Windows 10 1803 (17134) and later builds.

:k_pkey

call :dk_reflection

set d1=%ref% [void]$TypeBuilder.DefinePInvokeMethod('SkuGetProductKeyForEdition', 'pkeyhelper.dll', 'Public, Static', 1, [int], @([int], [String], [String].MakeByRefType(), [String].MakeByRefType()), 1, 3);
set d1=%d1% $out = ''; [void]$TypeBuilder.CreateType()::SkuGetProductKeyForEdition(%1, %2, [ref]$out, [ref]$null); $out

set pkey=
for /f %%a in ('%psc% "%d1%"') do if not errorlevel 1 (set pkey=%%a)
exit /b

::  Get channel name for the key which was extracted from pkeyhelper.dll

:k_pkeychannel

set k=%1
set m=[Runtime.InteropServices.Marshal]
set p=%SysPath%\spp\tokens\pkeyconfig\pkeyconfig.xrm-ms

set d1=%ref% [void]$TypeBuilder.DefinePInvokeMethod('PidGenX', 'pidgenx.dll', 'Public, Static', 1, [int], @([String], [String], [String], [int], [IntPtr], [IntPtr], [IntPtr]), 1, 3);
set d1=%d1% $r = [byte[]]::new(0x04F8); $r[0] = 0xF8; $r[1] = 0x04; $f = %m%::AllocHGlobal(0x04F8); %m%::Copy($r, 0, $f, 0x04F8);
set d1=%d1% [void]$TypeBuilder.CreateType()::PidGenX('%k%', '%p%', '00000', 0, 0, 0, $f); %m%::Copy($f, $r, 0, 0x04F8); %m%::FreeHGlobal($f); [Text.Encoding]::Unicode.GetString($r, 1016, 128)

set pkeychannel=
for /f %%a in ('%psc% "%d1%"') do if not errorlevel 1 (set pkeychannel=%%a)
exit /b

:ced_windowskey

for %%# in (pkeyhelper.dll) do @if "%%~$PATH:#"=="" exit /b
for %%# in (%keyflow%) do (
call :k_pkey %targetSKU% '%%#'
if defined pkey call :k_pkeychannel !pkey!
if /i "!pkeychannel!"=="%%#" (
set key=!pkey!
exit /b
)
)
exit /b

::========================================================================================================================================

:ced_targetSKU

set k=%1
set targetSKU=
for %%# in (pkeyhelper.dll) do @if "%%~$PATH:#"=="" exit /b

call :dk_reflection

set d1=%ref% [void]$TypeBuilder.DefinePInvokeMethod('GetEditionIdFromName', 'pkeyhelper.dll', 'Public, Static', 1, [int], @([String], [int].MakeByRefType()), 1, 3);
set d1=%d1% $out = 0; [void]$TypeBuilder.CreateType()::GetEditionIdFromName('%k%', [ref]$out); $out

for /f %%a in ('%psc% "%d1%"') do if not errorlevel 1 (set targetSKU=%%a)
if "%targetSKU%"=="0" set targetSKU=
exit /b

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

::  https://github.com/asdcorp/Set-WindowsCbsEdition

:cbsxml:[
param (
    [Parameter()]
    [String]$SetEdition,

    [Parameter()]
    [Switch]$GetTargetEditions,

    [Parameter()]
    [Switch]$StageCurrent
)

function Get-AssemblyIdentity {
    param (
        [String]$PackageName
    )

    $PackageName = [String]$PackageName
    $packageData = ($PackageName -split '~')

    if($packageData[3] -eq '') {
        $packageData[3] = 'neutral'
    }

    return "<assemblyIdentity name=`"$($packageData[0])`" version=`"$($packageData[4])`" processorArchitecture=`"$($packageData[2])`" publicKeyToken=`"$($packageData[1])`" language=`"$($packageData[3])`" />"
}

function Get-SxsName {
    param (
        [String]$PackageName
    )

    $name = ($PackageName -replace '[^A-z0-9\-\._]', '')

    if($name.Length -gt 40) {
        $name = ($name[0..18] -join '') + '\.\.' + ($name[-19..-1] -join '')
    }

    return $name.ToLower()
}

function Find-EditionXmlInSxs {
    param (
        [String]$Edition
    )

    $candidates = @($Edition, 'Client', 'Server')
    $winSxs = $Env:SystemRoot + '\WinSxS'
    $allInSxs = Get-ChildItem -Path $winSxs | select Name

    foreach($candidate in $candidates) {
        $name = Get-SxsName -PackageName "Microsoft-Windows-Editions-$candidate"
        $packages = $allInSxs | where name -Match ('^.*_'+$name+'_31bf3856ad364e35')

        if($packages.Length -eq 0) {
            continue
        }

        $package = $packages[-1].Name
        $testPath = $winSxs + "\$package\" + $Edition + 'Edition.xml'

        if(Test-Path -Path $testPath -PathType Leaf) {
            return $testPath
        }
    }

    return $null
}

function Find-EditionXml {
    param (
        [String]$Edition
    )

    $servicingEditions = $Env:SystemRoot + '\servicing\Editions'
    $editionXml = $Edition + 'Edition.xml'

    $editionXmlInServicing = $servicingEditions + '\' + $editionXml

    if(Test-Path -Path $editionXmlInServicing -PathType Leaf) {
        return $editionXmlInServicing
    }

    return Find-EditionXmlInSxs -Edition $Edition
}

function Write-UpgradeCandidates {
    param (
        [HashTable]$InstallCandidates
    )

    $editionCount = 0
        Write-Host '可升級至的版本：'
    foreach($candidate in $InstallCandidates.Keys) {
        Write-Host "Target Edition : $candidate"
        $editionCount++
    }

    if($editionCount -eq 0) {
                Write-Host '（沒有可用的版本）'
    }
}

function Write-UpgradeXml {
    param (
        [Array]$RemovalCandidates,
        [Array]$InstallCandidates,
        [Boolean]$Stage
    )

    $removeAction = 'remove'
    if($Stage) {
        $removeAction = 'stage'
    }

    Write-Output '<?xml version="1.0"?>'
    Write-Output '<unattend xmlns="urn:schemas-microsoft-com:unattend">'
    Write-Output '<servicing>'

    foreach($package in $InstallCandidates) {
        Write-Output '<package action="install">'
        Write-Output (Get-AssemblyIdentity -PackageName $package)
        Write-Output '</package>'
    }

    foreach($package in $RemovalCandidates) {
        Write-Output "<package action=`"$removeAction`">"
        Write-Output (Get-AssemblyIdentity -PackageName $package)
        Write-Output '</package>'
    }

    Write-Output '</servicing>'
    Write-Output '</unattend>'
}

function Write-Usage {
    Get-Help $script:MyInvocation.MyCommand.Path -detailed
}

$version = '1.0'
$getTargetsParam = $GetTargetEditions.IsPresent
$stageCurrentParam = $StageCurrent.IsPresent

if($SetEdition -eq '' -and ($false -eq $getTargetsParam)) {
    Write-Usage
    Exit 1
}

$removalCandidates = @();
$installCandidates = @{};

$packages = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages' | select Name | where { $_.name -match '^.*\\Microsoft-Windows-.*Edition~' }
foreach($package in $packages) {
    $state = (Get-ItemProperty -Path "Registry::$($package.Name)").CurrentState
    $packageName = ($package.Name -split '\\')[-1]
    $packageEdition = (($packageName -split 'Edition~')[0] -split 'Microsoft-Windows-')[-1]

    if($state -eq 0x40) {
        if($null -eq $installCandidates[$packageEdition]) {
            $installCandidates[$packageEdition] = @()
        }

        if($false -eq ($installCandidates[$packageEdition] -contains $packageName)) {
            $installCandidates[$packageEdition] = $installCandidates[$packageEdition] + @($packageName)
        }
    }

    if((($state -eq 0x50) -or ($state -eq 0x70)) -and ($false -eq ($removalCandidates -contains $packageName))) {
        $removalCandidates = $removalCandidates + @($packageName)
    }
}

if($getTargetsParam) {
    Write-UpgradeCandidates -InstallCandidates $installCandidates
    Exit
}

if($false -eq ($installCandidates.Keys -contains $SetEdition)) {
        Write-Error "系統無法升級到 `"$SetEdition`""
    Exit 1
}

$xmlPath = $Env:SystemRoot + '\Temp' + "\$([Guid]::NewGuid().Guid)CbsUpgrade.xml"

Write-UpgradeXml -RemovalCandidates $removalCandidates `
    -InstallCandidates $installCandidates[$SetEdition] `
    -Stage $stageCurrentParam >$xmlPath

$editionXml = Find-EditionXml -Edition $SetEdition
if($null -eq $editionXml) {
        Write-Warning '找不到版本專屬設定 XML。將在沒有它的情況下繼續...'
}

Write-Host '正在開始升級程序。這可能需要一段時間...'

DISM.EXE /English /NoRestart /Online /Apply-Unattend:$xmlPath
$dismError = $LASTEXITCODE

Remove-Item -Path $xmlPath -Force

if(($dismError -ne 0) -and ($dismError -ne 3010)) {
        Write-Error '升級到目標版本失敗'
    Exit $dismError
}

if($null -ne $editionXml) {
    $destination = $Env:SystemRoot + '\' + $SetEdition + '.xml'
    Copy-Item -Path $editionXml -Destination $destination

    DISM.EXE /English /NoRestart /Online /Apply-Unattend:$editionXml
    $dismError = $LASTEXITCODE

    if(($dismError -ne 0) -and ($dismError -ne 3010)) {
                Write-Error '套用版本專屬設定失敗'
        Exit $dismError
    }
}

Restart-Computer
:cbsxml:]

::========================================================================================================================================

::  Change edition using DISM API
::  Thanks to Alex (aka may, ave9858)

:dismapi:[
param (
    [Parameter()]
    [String]$TargetEdition,

    [Parameter()]
    [String]$Key
)

$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
$TB = $ModuleBuilder.DefineType(0)

[void]$TB.DefinePInvokeMethod('DismInitialize', 'DismApi.dll', 22, 1, [int], @([int], [IntPtr], [IntPtr]), 1, 3)
[void]$TB.DefinePInvokeMethod('DismOpenSession', 'DismApi.dll', 22, 1, [int], @([String], [IntPtr], [IntPtr], [UInt32].MakeByRefType()), 1, 3)
[void]$TB.DefinePInvokeMethod('_DismSetEdition', 'DismApi.dll', 22, 1, [int], @([UInt32], [String], [String], [IntPtr], [IntPtr], [IntPtr]), 1, 3)
$Dism = $TB.CreateType()

[void]$Dism::DismInitialize(2, 0, 0)
$Session = 0
[void]$Dism::DismOpenSession('DISM_{53BFAE52-B167-4E2F-A258-0A37B57FF845}', 0, 0, [ref]$Session)
if (!$Dism::_DismSetEdition($Session, "$TargetEdition", "$Key", 0, 0, 0)) {
    Restart-Computer
}
:dismapi:]

::========================================================================================================================================

::  1st column = Generic Retail/OEM/MAK/GVLK Key
::  2nd column = Key Type
::  3rd column = WMI Edition ID
::  4th column = Version name incase same Edition ID is used in different OS versions with different key
::  Separator  = _

::  For Windows 10/11 editions, HWID key is listed where ever possible, in Server versions, KMS key is listed where ever possible.
::  For Windows, generic keys are mentioned till 22000 and for Server, generic keys are mentioned till 17763, later ones are extracted from the pkeyhelper.dll

:changeeditiondata

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
if %winbuild% GTR 17763 exit /b
) else (
if %winbuild% GEQ 22000 exit /b
)
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*CorEdition~*.mum" (set Cor=Cor) else (set Cor=)

set w=
for %%# in (
XGVPP-NMH47-7TTHJ-W3FW7-8HV%w%2C__OEM:NONSLP_Enterprise
D6RD9-D4N8T-RT9QX-YW6YT-FCW%w%WJ______Retail_Starter
3V6Q6-NQXCX-V8YXR-9QCYV-QPF%w%CT__Volume:MAK_EnterpriseN
3NFXW-2T27M-2BDW6-4GHRV-68X%w%RX______Retail_StarterN
VK7JG-NPHTM-C97JM-9MPGT-3V6%w%6T______Retail_Professional
2B87N-8KFHP-DKV6R-Y2C8J-PKC%w%KT______Retail_ProfessionalN
4CPRK-NM3K3-X6XXQ-RXX86-WXC%w%HW______Retail_CoreN
N2434-X9D7W-8PF6X-8DV9T-8TY%w%MD______Retail_CoreCountrySpecific
BT79Q-G7N6G-PGBYW-4YWX6-6F4%w%BT______Retail_CoreSingleLanguage
YTMG3-N6DKC-DKB77-7M9GH-8HV%w%X7______Retail_Core
XKCNC-J26Q9-KFHD2-FKTHY-KD7%w%2Y__OEM:NONSLP_PPIPro
YNMGQ-8RYV3-4PGQ3-C8XTP-7CF%w%BY______Retail_Education
84NGF-MHBT6-FXBX8-QWJK7-DRR%w%8H______Retail_EducationN
KCNVH-YKWX8-GJJB9-H9FDT-6F7%w%W2__Volume:MAK_EnterpriseS_VB
43TBQ-NH92J-XKTM7-KT3KK-P39%w%PB__OEM:NONSLP_EnterpriseS_RS5
NK96Y-D9CD8-W44CQ-R8YTK-DYJ%w%WX__OEM:NONSLP_EnterpriseS_RS1
FWN7H-PF93Q-4GGP8-M8RF3-MDW%w%WW__OEM:NONSLP_EnterpriseS_TH
RQFNW-9TPM3-JQ73T-QV4VQ-DV9%w%PT__Volume:MAK_EnterpriseSN_VB
M33WV-NHY3C-R7FPM-BQGPT-239%w%PG__Volume:MAK_EnterpriseSN_RS5
2DBW3-N2PJG-MVHW3-G7TDK-9HK%w%R4__Volume:MAK_EnterpriseSN_RS1
NTX6B-BRYC2-K6786-F6MVQ-M7V%w%2X__Volume:MAK_EnterpriseSN_TH
G3KNM-CHG6T-R36X3-9QDG6-8M8%w%K9______Retail_ProfessionalSingleLanguage
HNGCC-Y38KG-QVK8D-WMWRK-X86%w%VK______Retail_ProfessionalCountrySpecific
DXG7C-N36C4-C4HTG-X4T3X-2YV%w%77______Retail_ProfessionalWorkstation
WYPNQ-8C467-V2W6J-TX4WX-WT2%w%RQ______Retail_ProfessionalWorkstationN
8PTT6-RNW4C-6V7J2-C2D3X-MHB%w%PB______Retail_ProfessionalEducation
GJTYN-HDMQY-FRR76-HVGC7-QPF%w%8P______Retail_ProfessionalEducationN
C4NTJ-CX6Q2-VXDMR-XVKGM-F9D%w%JC__Volume:MAK_EnterpriseG
46PN6-R9BK9-CVHKB-HWQ9V-MBJ%w%Y8__Volume:MAK_EnterpriseGN
NJCF7-PW8QT-3324D-688JX-2YV%w%66______Retail_ServerRdsh
XQQYW-NFFMW-XJPBH-K8732-CKF%w%FD______OEM:DM_IoTEnterprise
QPM6N-7J2WJ-P88HH-P3YRH-YY7%w%4H__OEM:NONSLP_IoTEnterpriseS
K9VKN-3BGWV-Y624W-MCRMQ-BHD%w%CD______Retail_CloudEditionN
KY7PN-VR6RX-83W6Y-6DDYQ-T6R%w%4W______Retail_CloudEdition
V3WVW-N2PV2-CGWC3-34QGF-VMJ%w%2C______Retail_Cloud
NH9J3-68WK7-6FB93-4K3DF-DJ4%w%F6______Retail_CloudN
2HN6V-HGTM8-6C97C-RK67V-JQP%w%FD______Retail_CloudE
WC2BQ-8NRM3-FDDYY-2BFGV-KHK%w%QY_Volume:GVLK_ServerStandard%Cor%_RS1
CB7KF-BWN84-R7R2Y-793K2-8XD%w%DG_Volume:GVLK_ServerDatacenter%Cor%_RS1
JCKRF-N37P4-C2D82-9YXRT-4M6%w%3B_Volume:GVLK_ServerSolution_RS1
QN4C6-GBJD2-FB422-GHWJK-GJG%w%2R_Volume:GVLK_ServerCloudStorage_RS1
VP34G-4NPPG-79JTQ-864T4-R3M%w%QX_Volume:GVLK_ServerAzureCor_RS1
9JQNQ-V8HQ6-PKB8H-GGHRY-R62%w%H6______Retail_ServerAzureNano_RS1
VN8D3-PR82H-DB6BJ-J9P4M-92F%w%6J______Retail_ServerStorageStandard_RS1
48TQX-NVK3R-D8QR3-GTHHM-8FH%w%XC______Retail_ServerStorageWorkgroup_RS1
2HXDN-KRXHB-GPYC7-YCKFJ-7FV%w%DG_Volume:GVLK_ServerDatacenterACor_RS3
PTXN8-JFHJM-4WC78-MPCBR-9W4%w%KR_Volume:GVLK_ServerStandardACor_RS3
) do (
for /f "tokens=1-4 delims=_" %%A in ("%%#") do if /i %targetedition%==%%C (

if not defined key (
set 4th=%%D
if not defined 4th (
set "key=%%A" & set "_chan=%%B"
) else (
echo "%branch%" | find /i "%%D" %nul1% && (set "key=%%A" & set "_chan=%%B")
)
)
)
)
exit /b

::========================================================================================================================================
:: Leave empty line below
