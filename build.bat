REM echo off
echo Building ...
set ROOT_DIR=%~dp0
cd %ROOT_DIR%

set SIGNTOOL_PATH=C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\SignTool.exe
set CODESIGNCERT_PATH=D:\comodo.pfx

call flutter clean
call flutter build windows

echo Signing...

"%SIGNTOOL_PATH%" sign /f "%CODESIGNCERT_PATH%" /fd SHA1 /t http://timestamp.sectigo.com "%ROOT_DIR%\build\windows\x64\runner\Release\thermal_tools.exe"

echo Running innosetup...

installtools\innosetup\iscc /Qp "/Ssigntool=%SIGNTOOL_PATH% sign /f %CODESIGNCERT_PATH% /fd SHA1 /t http://timestamp.sectigo.com $f" innosetup.iss



