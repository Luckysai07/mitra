@echo off
title Mitra App Launcher

set "PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\flutter\flutter\bin;C:\flutter\flutter\bin\cache\dart-sdk\bin"

cd /d "%~dp0"

echo ============================================
echo    Resolving packages and launching Mitra...
echo ============================================
echo.

if exist "build" rd /s /q "build" 2>nul
if not exist "build\web\assets\shaders" mkdir "build\web\assets\shaders" 2>nul

"C:\flutter\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\flutter\bin\cache\flutter_tools.snapshot" pub get

"C:\flutter\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\flutter\bin\cache\flutter_tools.snapshot" run -d chrome --release

pause
