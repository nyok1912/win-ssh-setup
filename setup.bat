@echo off
color 3
set "params=%*"
setlocal EnableDelayedExpansion
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || (
	echo ============================================================
	echo ERROR: Run The Script As Administrator.
	echo ============================================================
	echo.
	echo.
	echo Press any key to exit...
	pause >nul
	goto :eof
)

set "user="
set "pass="
set "ScriptURL=https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1"

:: Handle params
:parse_args
if "%~1"=="" goto end_parse
if "%~1"=="user" set "user=%2" & shift & shift & goto parse_args
if "%~1"=="pass" set "pass=%2" & shift & shift & goto parse_args
:end_parse

if not "%user%"=="" if not "%pass%"=="" (
    echo Params provided: 
	echo Username: %user%
	echo Password: %pass%
)

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ([scriptblock]::Create((Invoke-RestMethod -Uri '%ScriptURL%'))).Invoke('%user%', '%pass%');}"
REM powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%CD%\install.ps1\" -user \"myUser\" -pass \"myPassword\" '" -Verb RunAs"