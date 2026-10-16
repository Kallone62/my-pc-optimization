@echo off
setlocal EnableExtensions
echo Audit/download mode is now the ONLY supported mode.
call "%~dp0Download_Gaming_Drivers.cmd"
exit /b %ERRORLEVEL%
