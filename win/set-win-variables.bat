rem This should be executed using ADMIN role!
rem wmic is good!!!! 
rem cannot use Chinese words !!!

setx -m "JAVA_HOME" "%USERPROFILE%\xsoft\dev\sdk\jdk\jdk11"
setx -m "GRADLE_HOME" "%USERPROFILE%\xsoft\dev\build\gradle"
setx -m "GRADLE_USER_HOME" "D:\Download\aaaa\app-temp\repos"
setx -m "EXE4J_JAVA_HOME" %JAVA_HOME%
setx -m "GROOVY_HOME" "%USERPROFILE%\xsoft\dev\sdk\groovy"
setx -m "GOROOT" "%USERPROFILE%\xsoft\dev\sdk\go"
rem setx -m "GOPATH" "%USERPROFILE%\xcodes\mygo"

set DEFAULT_TEMP="C:\Temp\winTemp"
setx -m "TEMP" "%DEFAULT_TEMP%"
setx -m "TMP" "%DEFAULT_TEMP%"

set PYTHON_HOME="%USERPROFILE%\xsoft\dev\python"

rem set SSLKEYLOGFILE to make wireshark can get ssh key from explore
@REM setx -m "SSLKEYLOGFILE" "D:\Download\1112\winTemp\wireshark-sslkey-log.log"

@REM 删除sslkeylogfile变量
wmic ENVIRONMENT where "name='SSLKEYLOGFILE'" delete

set GIT_HOME=%USERPROFILE%\xsoft\dev\build\git\bin

rem set git configuration
%GIT_HOME%\git config --global core.excludefile %USERPROFILE%\xcodes\xops\0_system_files\dev-config\git-default-ignore
%GIT_HOME%\git config --global core.longpaths true
%GIT_HOME%\git config --global credential.helper !"%USERPROFILE%\xsoft\dev\build\git\mingw64\libexec\git-core\git-credential-store.exe"

set DEFAULT_PATH="C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Users\xjming\AppData\Local\Microsoft\WindowsApps"
@REM set DEFAULT_PATH=""
setx -m PATH "%JAVA_HOME%\bin;%GOROOT%\bin;%PYTHON_HOME%;%PYTHON_HOME%\Scripts;%GIT_HOME%;%GRADLE_HOME%\bin;%GROOVY_HOME%\bin;%DEFAULT_PATH%";"%USERPROFILE%\xsoft\bin
