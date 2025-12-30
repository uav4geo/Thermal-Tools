REM echo off
echo Building ...
set ROOT_DIR=%~dp0
cd %ROOT_DIR%

set SIGNTOOL_PATH=C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\SignTool.exe
set CODESIGNCERT_NAME=Open Source Developer, Piero Toffanin

call flutter clean
call flutter build windows

echo Signing...

"%SIGNTOOL_PATH%" sign /n "%CODESIGNCERT_NAME%" /fd SHA1 /t http://time.certum.pl "%ROOT_DIR%\build\windows\x64\runner\Release\thermal_tools.exe"

echo Running innosetup...

installtools\innosetup\iscc /Qp "/Ssigntool=%SIGNTOOL_PATH% sign /a /fd SHA1 /t http://time.certum.pl $f" innosetup.iss


