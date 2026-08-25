@echo off
:: Mitra App - Flutter Helper Script
:: Usage: run.bat [command]
:: Examples:
::   run.bat doctor
::   run.bat pub get
::   run.bat run -d chrome

:: Fix PATHEXT (required on this system)
set "PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"

:: Ensure system paths are available
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\flutter\flutter\bin;C:\flutter\flutter\bin\cache\dart-sdk\bin"

:: Run the flutter command with all arguments passed to this script
"C:\flutter\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\flutter\bin\cache\flutter_tools.snapshot" %*
