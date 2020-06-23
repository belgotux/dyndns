#!/bin/bash
# Auteur : Belgotux
# Site : http://www.monlinux.net
# Adresse : belgotux@monlinux.net
# Version : 1.0
# Date : 23-06-20
# Licence : Creative Commons CC-BY-NC-SA (https://creativecommons.org/licenses/by-nc-sa/4.0/) (ou GPLv3 https://www.gnu.org/licenses/gpl-3.0.html)
# Description : Check changes of the public IP and use dyndns standard to renew the DNS if needed. Tested with OVH

. /usr/local/etc/$(basename $0 .sh).conf

log=/var/log/$(basename $0 .sh).log
err=/var/log/$(basename $0 .sh).err

## end variables

# Check dependances
which curl >/dev/null
if [ $? != 0 ] ; then
        echo "curl is needed" 1>&2
        exit 1
fi
which dig >/dev/null
if [ $? != 0 ] ; then
        echo "dig is needed" 1>&2
        exit 1
fi


TIME=`date +'%d-%m-%Y %H:%M:%S'`
myip=$(curl -s $website_return_ip)

if [ $? != 0 ] ; then
        echo "$TIME Error to get an IP from $website_return_ip" | tee -a $log | tee -a $err 1>&2
        exit 2
fi

actual_ip_in_dns=$(dig +short @$dns_resolver $domain)

regexpip="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
if [[ "$myip" =~ $regexpip ]] ; then
        if [ "$myip" == "$actual_ip_in_dns" ] ; then
          echo "$TIME Same IP $myip nothing to do" >> $log
          exit 0
        fi

        returnProvider=$(curl -s -u $username:$pass "$url_provider_dyndns&hostname=$domain&myip=$myip")
        if [ $? != 0 ] ; then
          echo "$TIME Error to put the IP $myip to the provider $url_provider_dyndns for the domain $domain and username $username" | tee -a $log | tee -a $err 1>&2
          exit 3
        fi
        case $returnProvider in
          "notfqdn")
            echo "$TIME $domain The hostname specified is not a fully-qualified domain name" | tee -a $log | tee -a $err 1>&2 ;;
          "badauth")
            echo "$TIME Authenticate failed" | tee -a $log | tee -a $err 1>&2 ;;
          "good $myip")
            echo "$TIME Update successfully $domain with IP $myip" >> $log ;;
          *)
            echo "$TIME Error received from provider : $returnProvider" | tee -a $log | tee -a $err 1>&2 ;;
        esac
else

        echo "$TIME Error the IP $myip doesn't respect the good format" | tee -a $log | tee -a $err 1>&2
        exit 4
fi

exit 0
