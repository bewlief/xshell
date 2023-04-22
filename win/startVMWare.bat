sc config "VMAuthdService" start=AUTO 
sc config "VMUSBArbService" start=AUTO 
sc config "VMnetDHCP" start=AUTO 
sc config "VMware NAT Service" start=AUTO 
sc config "VMwareHostd" start=AUTO 

rem netsh interface set interface VMnet8 enabled

net start "VMAuthdService"
net start "VMnetDHCP"
net start "VMware NAT Service"
net start "VMUSBArbService"
net start "VMwareHostd"

rem start "" "C:\Program Files (x86)\VMware\vmware.exe"