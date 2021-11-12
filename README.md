# Dyndns script

Check changes of the public IPv4 and use dyndns standard to renew the DNS if needed.


## Providers
This script was tested on one provider now, but work with generic dyndns protocol. Feel free to add another one.
- OVH

## Installation
1. Copy dyndns.sh to /usr/local/bin
2. Copy dyndns.conf.example to /usr/local/etc/dyndns.conf
3. Put your credentials to the file dydns.conf
4. Copy dyndns.logrotate to /etc/logrotate.d/dyndns

```
url_provider_dyndns="http://www.ovh.com/nic/update?system=dyndns"
username="xxxxxxxxxx"
pass="xxxxxxxxxxxxx"
```

## Log
Logs are created in /var/log/ :
- dyndns.log : normal log like "nothing to do" or "IP change for xxx.xxx.xxx.xxx"
- dyndns.err : error log, like error with resolver, dns server for provider errors

## Cron
When the script work, create a contab like : 
```
*/10 * * * *    root    /usr/local/bin/dyndns.sh
```
In normal use, the script doesn't output anything.
If any error appeared, the script output in stderr to use the cron's mailto feature
## Logrotate

With the cron, the log is generated every 10minutes. Big log at the end of the week, need to rotate the logs!
```
/var/log/dyndns.log /var/log/dyndns.err {
    weekly
    rotate 8
    compress
    missingok
    copytruncate
}
```
