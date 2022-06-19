# xops lib: 让你的开发更加迅速！

## 简介
这是一个基于git bash的bash脚本开发库！如果你是一个程序员，且是重度自动化爱好者，那么，这个库应该会对你有所裨益。
+ 基于git bash，无需顾虑跨平台问题；
+ git，必不可少的大杀器，装了git，即有了本库的运行环境；
+ 规范化的目录架构，让你的系统快速恢复开发环境；
+ 内置多个实用工具，如git repo的刷新、针对目录的bookmark等；
+ 灵活实用的引入机制

## 目录说明
+ /config/： 配置文件，包含系统全局变量、git repo config等
+ /ext/： 扩展，该目录下的 *.sh 在bash初始化时会自动导入
+ /lib/： xops lib，核心部分，包含core、meta、string等开发库
+ /tool/： 基于本库开发的一些工具
+ /win/： 适用于windows环境
+ /\*.\*：多个实用工具，如：
  + xbash-profile.sh： 由.bash_profile引入，构建本机开发环境
  + git-refresh.sh: 基于xops lib的git repo刷新工具，用于批量刷新repo
  + backup.sh：基于xops lib的备份工具，备份内容在脚本中设置
  + clean.sh：清理垃圾文件
  + set-win-variables.bat：设置windows系统的环境变量，运行时需要管理员权限
  + start.jsh：用于jshell，初始化环境


## 如何使用

1. 克隆本repo

2. 修改 $HOME/.bash_profile.sh，加入xbash-profile.sh的引用

   ```shell
   # global configuration file
   export GLOBAL_INI="$HOME/xcodes/xops/xshell/config/global-xjming.ini"
   
   xprofile=$HOME/xcodes/xops/xshell/xbash-profile.sh
   [[ -f $xprofile ]] && source $xprofile
   ```

   + GLOBAL_INI：该变量指向系统全局变量 global-xjming.ini，实际上也是一个sh文件，用于设置一些全局变量

   + source $xprofile：调用了 xbash-profile.sh

3. 重启git bash即可

## xops lib使用说明

1. xops lib，指的是 /lib/下的sh文件，是我多年来写shell脚本的积累，大部分都是基于自己的实际需求而来，也参考了网上很多的代码实现。

2. 不以x开头的.sh，是核心的代码，x*.sh则以核心库为基础。

   ### 库文件介绍

   + **core.sh**：最最核心的文件，要使用xops lib，必须首先导入该sh！其他的lib也都是首先引入了它。

     + 定义了多个关键的全局变量：
       + XLIB_BASE： lib所在的路径，如 $HOME/xcodes/xops/xshell/lib
       + XLIB_BASE_PARENT： lib所在路径的父目录，如 $HOME/xcodes/xops/xshell
       + XLIB_BASE_EXT： ext目录的绝对路径
       + XLIB_BASE_BIN: bin目录的绝对路径
       + XLIB_BASE_CONFIG： config目录的绝对路径
       + XLIB_CORE： core.sh的绝对路径 

   + 定义了最基本的alias

   + 定义了最基本的 info，warn，error函数

   + 定义了ext、lib等的引入函数：import，reload

   + 实现了$PATH的添加、去重、移除

     #### 如何导入：

```shell
   function __xbash_init__() {
       # xbash-profile也是基于lib，core
       [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
           local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
           source "$script_dir/lib/core.sh"
       }
   
       import meta
   }
```

   这是xbash-profile.sh中的core.sh的引入。注意source部分，需要指明core.sh的路径。

   在core.sh导入后，即可使用 import color; import xwin等形式去引入其他lib。

 + meta.sh：系统相关，其中的 meta::getopts 比较重要，用于命令行参数的解析。

 + string.sh：string操作相关的函数，如随机字符串、截取、大小写转换、格式化、拆分等。

 + cache.sh：以文件系统实现的cache

 + dict.sh：内存中的key-value存取

 + color.sh：ansi color的操作

 + --


## 分享下我的开发环境设置
### 基本目录结构
有3个基本目录，都在$HOME/下，windows环境下，一般是 C:\Users\{your-account}\
+ /xsoft/
尽量使用绿色化软件，除非像vmware workstation之类的必须安装的。
```shell
.                                                                                  
|-- Media                                                                          
|   |-- ACDSee Classic Chs.exe                                                     
|   |-- CHKenPlayer                                                                
|   |-- Honeyview                                                                  
|   |-- Imagine                                                                    
|   |-- PSDViewer                                                                  
|   |-- Picasa3                                                                    
|   |-- foobar2000                                                                 
|   |-- mpc-hc_64                                                                  
|   `-- translator                                                                 
|-- bin                                                                            
|   |-- DragExt64.dll                                                              
|   |-- FileActivityWatch.exe                                                      
。。。。。。                                                   
|   |-- xml.exe                                                                    
|   |-- xxd.exe                                                                    
|   |-- zip.exe                                                                    
|   `-- zlib1.dll                                                                  
|-- database                                                                       
|   |-- DBtools                                                                    
|   |-- activemq-5.16.0                                                            
|   |-- dbeaver-agent.jar                                                          
|   |-- h2                                                                         
|   |-- kafka                                                                      
|   |-- mariadb64                                                                  
|   |-- mssql                                                                      
|   |-- mysql                                                                      
|   |-- pgsql                                                                      
|   `-- redis                                                                      
|-- dev                                                                            
|   |-- JetBrains                                                                  
|   |-- LdapAdmin.exe                                                              
|   |-- Python                                                                     
|   |-- Servers                                                                    
|   |-- Testing                                                                    
|   |-- architect                                                                  
|   |-- build                                                                      
|   |-- jvmTools                                                                   
|   |-- sdk                                                                        
|   |-- vim                                                                        
|   `-- vscode                                                                     
|-- documents                                                                      
|   |-- Beyond Compare                                                             
|   |-- Calibre2                                                                   
|   |-- Notepad3                                                                   
|   |-- Sigil                                                                      
|   |-- Typora                                                                     
|   |-- WPS2016.7z                                                                 
|   |-- WinMerge                                                                   
|   |-- XPS Viewer                                                                 
|   |-- batchRename.exe                                                            
|   |-- emed64                                                                     
|   |-- npp7x64                                                                    
|   |-- pdfTools                                                                   
|   `-- txtUtils                                                                   
|-- hw                                                                             
|   `-- aida64ex                                                                   
|-- myPims                                                                         
|   |-- 2020-new-pass.xly                                                          
|   |-- 2020.xly                                                                   
|   |-- 2021.xly                                                                   
|   |-- DBManager.exe                                                              
|   |-- myPims.dat                                                                 
|   |-- mypims.exe                                                                 
|   `-- readme.txt                                                                 
|-- net                                                                            
|   |-- FileZilla                                                                  
|   |-- InletexEc.exe                                                              
|   |-- WeChat                                                                     
|   |-- WeMeet                                                                     
|   |-- Zoom                                                                       
|   `-- foxmail.7z                                                                 
|-- net-admin                                                                      
|   |-- Cisco TFTP Server.7z                                                       
|   |-- HyperTerm.7z                                                               
|   |-- Remote Desktop Connection Manager                                          
|   |-- SERV-U.7z                                                                  
|   |-- SecureCRT                                                                  
|   |-- UltraVNC                                                                   
|   |-- hercules_3-2-8.exe                                                         
|   |-- mac\265\330\326\267\320\336\270\304\306\367                                
|   |-- tftpd32.7z                                                                 
|   `-- xmanager                                                                   
|-- security                                                                       
|   |-- Fiddler                                                                    
|   |-- Nessus-6.9.1-x64.msi                                                       
|   |-- OWASP                                                                      
|   |-- WinPcap_4_1_3.exe                                                          
|   |-- Wireshark                                                                  
|   |-- burpsuite v1.7.11                                                          
|   |-- nmap-7.31                                                                  
|   `-- npcap-0.11.exe                                                             
`-- system                                                                         
    |-- 7z                                                                         
    |-- Allway Sync                                                                
    |-- ConEmu                                                                     
    |-- MenuMgr1.2.exe                                                             
    |-- Ontrack EasyRecovery11 Enterprise.7z                                       
    |-- clean                                                                      
    |-- sysinternals                                                               
    `-- tools                                                                      
```
+ /bin/：所有的命令行应用都放在这里，并加入到$PATH中。目前你可以从这里找到我精心收集的命令行工具： [https://github.com/bewlief/myrepo/tree/master/xops-bin](https://github.com/bewlief/myrepo/tree/master/xops-bin)

+ /database/：database server及client

+ /dev/：开发用

  + /architect/

  + /build/：git、maven、gradle等

  + /sdk/：java，golang的sdk

    + /jdk/：该目录下的所有目录都会被自动处理为jdk
    + /go/： golang的sdk
    + /lua/

    

    + /servers/：tomcat，jetty，nginx等
    + /test/：测试相关

+ /xdata/
+ /xcodes/ ：存放我的代码，如：
  + mycodes: 我的测试代码所在目录
  + xops/：用于OPS代码存放，本库代码即放在该目录的 /xshell/下

## 相关下载
本库使用到的一些命令行工具的下载路径：
+ git bash: https://git-scm.com/download/win
+ putty: https://www.puttygen.com/download-putty#Download_PuTTY_073_for_Windows
+ ctags: https://sourceforge.net/projects/ctags/
+ curl: https://curl.se/windows/
+ figlet: https://sourceforge.net/projects/figlet-for-windows/
+ jq: https://stedolan.github.io/jq/download/
+ junction: https://docs.microsoft.com/en-us/sysinternals/downloads/junction
+ mmt: MultiMonitorTool, https://www.nirsoft.net/utils/multi_monitor_tool.html
+ nircmd: https://www.nirsoft.net/
+ tree: http://gnuwin32.sourceforge.net/packages/tree.htm
+ xml: https://sourceforge.net/projects/xmlstar/files/
+ xxd: from vim, https://www.vim.org/download.php
+ zip: 使用7zip的7z.exe复制、更名为zip.exe, https://www.7-zip.org/
+ lsof: from sysinternals, handle64.exe, https://docs.microsoft.com/en-us/sysinternals/downloads/
+ rsync: 
  + https://gist.github.com/hisplan/ee54e48f17b92c6609ac16f83073dde6
  + rsync: http://repo.msys2.org/msys/x86_64/rsync-3.2.3-1-x86_64.pkg.tar.zst
  + libxxhash: http://repo.msys2.org/msys/x86_64/libxxhash-0.8.0-1-x86_64.pkg.tar.zst
  + liblzr: http://repo.msys2.org/msys/x86_64/liblz4-1.9.3-1-x86_64.pkg.tar.zst
  + libzstd: http://repo.msys2.org/msys/x86_64/libzstd-1.4.8-1-x86_64.pkg.tar.zst



## 欢迎bash爱好者的fork与push！

可以加我的微信哦：

[![xjming.jpg](https://i.postimg.cc/vZZkmHLN/xjming.jpg)](https://postimg.cc/Vd2DGwhq)

我还建了个微信群，欢迎您的入伙。

让我们一起来聊shell！
