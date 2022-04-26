sc config "VMAuthdService" start=DISABLED 
sc config "VMUSBArbService" start=DISABLED 
sc config "VMnetDHCP" start=DISABLED 
sc config "VMware NAT Service" start=DISABLED 
sc config "VMwareHostd" start=DISABLED 

rem netsh interface set interface VMnet8 disabled

net stop "VMwareHostd"
net stop "VMUSBArbService"
net stop "VMnetDHCP"
net stop "VMware NAT Service"
net stop "VMAuthdService"

TASKKILL /F /FI "imagename eq vmware*"
TASKKILL /F /FI "imagename eq vmnat*"
TASKKILL /F /FI "imagename eq vmnetdhcp*"
TASKKILL /F /FI "imagename eq vmware-authd*"
TASKKILL /F /FI "imagename eq vmware-hostd*"
TASKKILL /F /FI "imagename eq vmware-unity-help*"
