@echo off
title Mitra Automated Test Runner

set "PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\flutter\flutter\bin;C:\flutter\flutter\bin\cache\dart-sdk\bin"

cd /d "%~dp0"

echo ============================================
echo      Running Mitra Automated Test Suite...
echo ============================================
echo.

"C:\flutter\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\flutter\bin\cache\flutter_tools.snapshot" test

pause
