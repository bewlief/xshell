# Download SSL/TLS pem format cert from https web host:
openssl s_client -showcerts -connect baidu.com:443 </dev/null 2>/dev/null | openssl x509 -outform PEM >baidu.com.cer
