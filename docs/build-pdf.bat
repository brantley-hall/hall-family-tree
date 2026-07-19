@echo off
setlocal enabledelayedexpansion

:: Build script: regenerate final-ledger.pdf from final-ledger.html
:: Run this after editing final-ledger.html

set SOURCE=%~dp0final-ledger.html
set OUTPUT=%~dp0final-ledger.pdf
set EDGE="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if not exist %EDGE% (
    echo Microsoft Edge not found at %EDGE%
    echo Please update the EDGE path in this script.
    pause
    exit /b 1
)

if exist %OUTPUT% del %OUTPUT%

set URL=%SOURCE:\=/%

echo Generating PDF from %SOURCE%...
%EDGE% --headless --print-to-pdf=%OUTPUT% "file:///%URL%"

if exist %OUTPUT% (
    echo PDF created: %OUTPUT%
) else (
    echo PDF generation failed.
)

pause
