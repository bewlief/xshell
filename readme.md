# xops: 让你的开发更加迅速！

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
+ /lib/： 核心部分，包含core、meta、string等开发库
+ /tool/： 基于本库开发的一些工具
+ /win/： 适用于windows环境
+ /xbash-profile.sh： 由.bash_profile引入，构建本机开发环境


## 我的开发环境设置
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
|   |-- InstallCert.class                                                          
|   |-- LICENCE                                                                    
|   |-- MSVCR71.DLL                                                                
|   |-- PUTTY.CNT                                                                  
|   |-- PUTTY.HLP                                                                  
|   |-- README.txt                                                                 
|   |-- SQLCMD.EXE                                                                 
|   |-- SQLCMD.rll                                                                 
|   |-- WinSCP.chs                                                                 
|   |-- WinSCP.com                                                                 
|   |-- WinSCP.exe                                                                 
|   |-- WinSCP.ini                                                                 
|   |-- WinSCP.map                                                                 
|   |-- WinSCPnet.dll                                                              
|   |-- ab.exe                                                                     
|   |-- abs.exe                                                                    
|   |-- appnetworkcounter.cfg                                                      
|   |-- appnetworkcounter.exe                                                      
|   |-- batchparser.dll                                                            
|   |-- bc.exe                                                                     
|   |-- bcp.exe                                                                    
|   |-- bcp.rll                                                                    
|   |-- bfg-1.14.0.jar                                                             
|   |-- bfg-readme.md                                                              
|   |-- cacert.pem                                                                 
|   |-- crc32.exe                                                                  
|   |-- ctags.exe                                                                  
|   |-- curl.exe                                                                   
|   |-- dc.exe                                                                     
|   |-- etcd.exe                                                                   
|   |-- etcdctl.exe                                                                
|   |-- figlet0.exe                                                                
|   |-- flf                                                                        
|   |-- helm.exe                                                                   
|   |-- hey.exe                                                                    
|   |-- installedappview.cfg                                                       
|   |-- installedappview.exe                                                       
|   |-- jq.exe                                                                     
|   |-- junction.exe                                                               
|   |-- kubectl.exe                                                                
|   |-- libcrypto-1_1.dll                                                          
|   |-- libssl-1_1.dll                                                             
|   |-- libxml2.dll                                                                
|   |-- license.txt                                                                
|   |-- lsof.exe                                                                   
|   |-- mmt.cfg                                                                    
|   |-- mmt.exe                                                                    
|   |-- netpass.exe                                                                
|   |-- nircmd.exe                                                                 
|   |-- nircmdc.exe                                                                
|   |-- openedfilesview.cfg                                                        
|   |-- openedfilesview.exe                                                        
|   |-- osql.exe                                                                   
|   |-- pageant.exe                                                                
|   |-- plink.exe                                                                  
|   |-- pscp.exe                                                                   
|   |-- psftp.exe                                                                  
|   |-- pslist64.exe                                                               
|   |-- putty.chm                                                                  
|   |-- putty.exe                                                                  
|   |-- puttygen.exe                                                               
|   |-- puttytel.exe                                                               
|   |-- shellcheck.exe                                                             
|   |-- shellcheck1.exe                                                            
|   |-- shfmt_v3.4.0_darwin_amd64                                                  
|   |-- shfmt_v3.4.0_linux_386                                                     
|   |-- shfmt_v3.4.0_linux_amd64                                                   
|   |-- shfmt_v3.4.0_windows_386.exe                                               
|   |-- shfmt_v3.4.1_windows_amd64.exe                                             
|   |-- stickies.ico                                                               
|   |-- taskschedulerview.exe                                                      
|   |-- tcping.exe                                                                 
|   |-- telnet.exe                                                                 
|   |-- terraform.exe                                                              
|   |-- tree.exe                                                                   
|   |-- upx.exe                                                                    
|   |-- vix.dll                                                                    
|   |-- vmrun.exe                                                                  
|   |-- vnetlib.dll                                                                
|   |-- wget.exe                                                                   
|   |-- winhex.exe                                                                 
|   |-- wirelesskeyview.cfg                                                        
|   |-- wirelesskeyview.exe                                                        
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
+ /bin/：所有的命令行应用都放在这里，并加入到$PATH中
  + /database/：database server及client
  + /dev/：开发用
    + /architect/
    + /build/：git、maven、gradle等
    + /sdk/：java，golang的sdk
      + /jdk/：该目录下的所有目录都会被自动处理为jdk
      + /go/： golang的sd
      + /lua/
    + /servers/：tomcat，jetty，nginx等
    + /test/：测试相关
+ /xdata/
+ /xcodes/
存放我的代码，如：
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
