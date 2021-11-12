#!/bin/bash
# Auteur : Belgotux
# Site : http://www.monlinux.net
# Adresse : belgotux@monlinux.net
# Version : 1.1
# Date : 12/11/21
# Licence : Creative Commons CC-BY-NC-SA (https://creativecommons.org/licenses/by-nc-sa/4.0/)
# Description : Check changes of the public IPv4/IPv6 and use dyndns standard to renew the DNS if needed. Tested with OVH


## variables
log=/var/log/$(basename $0 .sh).log
err=/var/log/$(basename $0 .sh).err
alertFlag4=/tmp/$(basename $0 .sh)4.flag
alertFlag6=/tmp/$(basename $0 .sh)6.flag

if [ ! -e /usr/local/etc/$(basename $0 .sh).conf ] ; then 
	echo "please create /usr/local/etc/$(basename $0 .sh).conf first!" 1>&2
	exit 1
fi
. /usr/local/etc/$(basename $0 .sh).conf

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


# functions
function checkIP () {
	local myip="$1"
	local regexpip="$2"
	local actual_ip_in_dns="$3"
	local url_provider_dyndns_ip="$4"
	local alertFlag="$5"

	if [[ "$myip" =~ $regexpip ]] ; then
		if [ "$myip" == "$actual_ip_in_dns" ] ; then
			echo "$TIME Same IP $myip nothing to do" >> $log
			if [ -e $alertFlag ] ; then	
				rm $alertFlag
			fi
			return 0
		fi
		if [ "$url_provider_dyndns_ip" != "" ] ; then
			returnProvider=$(curl -s -u $username:$pass "$url_provider_dyndns_ip&hostname=$domain&myip=$myip")
			if [ $? != 0 ] ; then
			echo "$TIME Error to put the IP $myip to the provider $url_provider_dyndns_ip for the domain $domain and username $username" | tee -a $log | tee -a $err 1>&2
			return 3
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
			if [ ! -e $alertFlag ] ; then #avoid notification repetition
				echo "$TIME the new IP $myip is not the same as the record on $domain : $actual_ip_in_dns" | tee -a $log
				echo "$myip" > $alertFlag
			else
				echo "$TIME the new IP $myip is not the same as the record on $domain : $actual_ip_in_dns (repeat)" >> $log
			fi
			
		fi
	else
		echo "$TIME Error the IP $myip doesn't respect the good format" | tee -a $log | tee -a $err 1>&2
		return 4
	fi
}


TIME=`date +'%d-%m-%Y %H:%M:%S'`

if $check_ip4 ; then
	myip4=$(curl -4 -s $website_return_ip4)
	if [ $? != 0 ] ; then
		echo "$TIME Error to get an IP from $website_return_ip4" | tee -a $log | tee -a $err 1>&2
		exit 2
	fi
	actual_ip4_in_dns=$(dig +short @$dns_resolver $domain)

	regexpip4="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
	
	checkIP "$myip4" "$regexpip4" "$actual_ip4_in_dns" "$url_provider_dyndns_ip4" "$alertFlag4"
	returnIp4=$?
	
fi

if $check_ip6 ; then
	myip6=$(curl -6 -s $website_return_ip6)
	if [ $? != 0 ] ; then
		echo "$TIME Error to get an IP from $website_return_ip6" | tee -a $log | tee -a $err 1>&2
		exit 2
	fi
	actual_ip6_in_dns=$(dig +short -t AAAA @$dns_resolver $domain)

	regexpip6="^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$"

	checkIP "$myip6" "$regexpip6" "$actual_ip6_in_dns" "$url_provider_dyndns_ip6" "$alertFlag6"
	returnIp6=$?
fi

if [ $returnIp4==0 ] && [ $returnIp6 == 0 ] ; then
	exit 0
else
	exit 1
fi

# OVH Output:
#    When you write your own module, you can use the following words to tell user what happen by print it.
#    You can use your own message, but there is no multiple-language support.
#
#       good -  Update successfully.
#       nochg - Update successfully but the IP address have not changed.
#       nohost - The hostname specified does not exist in this user account.
#       abuse - The hostname specified is blocked for update abuse.
#       notfqdn - The hostname specified is not a fully-qualified domain name.
#       badauth - Authenticate failed.
#       911 - There is a problem or scheduled maintenance on provider side
#       badagent - The user agent sent bad request(like HTTP method/parameters is not permitted)
#       badresolv - Failed to connect to  because failed to resolve provider address.
#       badconn - Failed to connect to provider because connection timeout.
#
