@echo off
setlocal enabledelayedexpansion

rem Locate ringtest package directory
if exist "%~dp0..\tools\ringpm\packages\ringtest\main.ring" (
    set "RINGTEST_PKG=%~dp0..\tools\ringpm\packages\ringtest"
) else if exist "%~dp0..\tools\ringtest\main.ring" (
    set "RINGTEST_PKG=%~dp0..\tools\ringtest"
) else if exist "%~dp0..\main.ring" (
    set "RINGTEST_PKG=%~dp0.."
) else if exist "%~dp0..\..\main.ring" (
    set "RINGTEST_PKG=%~dp0..\.."
) else (
    echo Error: ringtest package files not found.
    exit /b 1
)

rem Capture caller current working directory
set "RINGTEST_CALLER_DIR=%CD%"
set "RINGTEST_HOME=%RINGTEST_PKG%"

rem Locate ring.exe from PATH using where command
set "RING_EXE=ring"
for /f "delims=" %%I in ('where ring.exe 2^>nul') do (
    set "RING_EXE=%%I"
    goto :found_ring
)

:found_ring
if not defined RING_EXE (
    echo Error: Could not locate ring.exe in PATH.
    exit /b 1
)

rem Run ringtest from its own directory but with caller's directory
pushd "%RINGTEST_PKG%"
"%RING_EXE%" main.ring %*
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%