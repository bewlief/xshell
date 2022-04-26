@echo off

:: Pass execution context information through environment variables.
set SUDO_CMDLINE=%*
set SUDO_ARG1=%1
set SUDO_ARG2=%2
set SUDO_CD="%CD%"
set SUDO_DRIVE=%CD:~0,2%

goto start 
: 变相的多行注释方式

: %~dpn0 is refering to this files name and %* sends along the full commandline  
: cscript //nologo "%~dpn0.vbs" %*

: %~dp0 “d”为Drive的缩写，即为驱动器，磁盘、“p”为Path缩写，即为路径，目录
: ~0 - 删除任何引号(")，扩充 %0
: %~f0 - 将 %0 扩充到一个完全合格的路径名(“f”是file，即文件)
: %~d0 - 仅将 %0 扩充到一个驱动器号
: %~p0 - 仅将 %0 扩充到一个路径
: %~n0 - 仅将 %0 扩充到一个文件名(“n”是name 文件名)
: %~x0 - 仅将 %0 扩充到一个文件扩展名
: %~s0 - 扩充的路径只含有短名(“s”为Short，短的)
: %~a0 - 将 %0 扩充到文件的文件属性(“a”为attribute，即属性)
: %~t0 - 将 %0 扩充到文件的日期/时间(“t”time)
: %~z0 - 将 %0 扩充到文件的大小(Size 大小)
: %~$PATH:0 - 查找列在路径环境变量的目录，并将 %0 扩充

: %~dp0 - 仅将 %0 扩充到一个驱动器号和路径
: %~nx0 - 仅将 %0 扩充到一个文件名和扩展名
: %~fs0 - 仅将 %0 扩充到一个带有短名的完整路径名
: %~dp$PATH:0 - 查找列在路径环境变量的目录，并将 %I 扩充
: 到找到的第一个驱动器号和路径。
: %~ftza0 - 将 %0 扩充到类似输出线路的 DIR

: %0为当前批处理文件
: 如果0换成1为第一个文件，2为第2个
:start 

C:\Windows\System32\cscript.exe //nologo "%~dp0/win/sudo.vbs" %*