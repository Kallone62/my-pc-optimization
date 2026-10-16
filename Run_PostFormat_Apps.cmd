@echo off
setlocal EnableExtensions
if not "%~1"=="" (
  echo This launcher is now DOWNLOAD-ONLY; command-line options are not supported.
  pause
  exit /b 2
)
echo Legacy launcher name: now DOWNLOAD + VERIFY ONLY.
call "%~dp0Download_PostFormat_Apps.cmd"
exit /b %ERRORLEVEL%
