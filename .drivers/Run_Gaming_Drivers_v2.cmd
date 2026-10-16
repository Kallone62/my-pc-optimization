@echo off
setlocal EnableExtensions
echo Legacy launcher name: now DOWNLOAD + VERIFY ONLY.
call "%~dp0Download_Gaming_Drivers.cmd"
exit /b %ERRORLEVEL%
