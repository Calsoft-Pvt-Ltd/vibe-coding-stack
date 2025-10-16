@echo off
REM Wrapper script to run PowerShell installation with visible console

echo ============================================
echo   Local Vibe Coding Stack Installation
echo   Please wait while components are installed...
echo ============================================
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "INSTALL_PS1=%SCRIPT_DIR%install.ps1"
set "CONFIG_JSON=%SCRIPT_DIR%..\assets\installer-config.json"

echo Starting PowerShell installation script...
echo Script: %INSTALL_PS1%
echo Config: %CONFIG_JSON%
echo.

REM Run PowerShell with visible output
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_PS1%" -ConfigPath "%CONFIG_JSON%"

set EXITCODE=%ERRORLEVEL%

echo.
echo ============================================
echo Installation script finished with code: %EXITCODE%
echo ============================================
echo.

if %EXITCODE% NEQ 0 (
    echo ERROR: Installation script failed!
    echo Check the log file at: %TEMP%\LocalVibeCodingStack-install.log
    echo.
    pause
    exit /b %EXITCODE%
)

echo Installation completed successfully!
echo.
pause
exit /b 0
