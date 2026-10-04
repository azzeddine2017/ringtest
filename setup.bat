@echo off
setlocal enabledelayedexpansion

echo Installing ringtest locally to Ring's bin folder...

set "RING_BIN="

:: 1. Check RINGPATH environment variable
if defined RINGPATH (
    if exist "%RINGPATH%\bin\ring.exe" set "RING_BIN=%RINGPATH%\bin"
)

:: 2. Find ring.exe from PATH using where command
if not defined RING_BIN (
    for /f "delims=" %%I in ('where ring.exe 2^>nul') do (
        set "RING_BIN=%%~dpI"
        goto :found_bin
    )
)

:found_bin
:: Remove trailing backslash if present
if defined RING_BIN (
    if "!RING_BIN:~-1!"=="\" set "RING_BIN=!RING_BIN:~0,-1!"
)

if not defined RING_BIN (
    echo Error: Could not locate ring.exe. Please ensure Ring is in your PATH.
    exit /b 1
)

set "TARGET=%RING_BIN%\ringtest.bat"
set "ROOT_DIR=%~dp0"

echo @echo off > "%TARGET%"
echo set "RINGTEST_CALLER_DIR=%%CD%%" >> "%TARGET%"
echo pushd "%ROOT_DIR%" ^>nul >> "%TARGET%"
echo ring "main.ring" %%* >> "%TARGET%"
echo popd ^>nul >> "%TARGET%"

echo [SUCCESS] ringtest wrapper created at: %TARGET%
echo You can now use 'ringtest' globally from any terminal!