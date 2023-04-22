
@echo off
%USERPROFILE%\xsoft\bin\mmt.exe /loadconfig %USERPROFILE%\xcodes\xops\xshell\config/monitor/%~1%.cfg

echo monitor changed to %USERPROFILE%\xcodes\xops\xshell\config/monitor/%~1%.cfg
exit
