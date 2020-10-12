#!/bin/bash
WWWHOST=`cat /wpmultienv/wwwhost`
if [ -f /var/www/html/wpmultienv/rewrites.conf ]; then
        cp -f /var/www/html/wpmultienv/rewrites.conf /var/www/html/wpmultienv/rewrites-env.conf
        perl -p -i -e "s/MAINURL/$WWWHOST/g" /var/www/html/wpmultienv/rewrites-env.conf
	md5a=`md5sum /var/www/html/wpmultienv/rewrites-env.conf | awk '{ print $1}'`
	md5b=`md5sum /etc/apache2/rewrites/rewrites.conf | awk '{ print $1}'`
	if [ "$md5a" != "$md5b" ]; then 
		echo "Refreshing rewrite rules..."
        	cp -f /var/www/html/wpmultienv/rewrites-env.conf /etc/apache2/rewrites/rewrites.conf
		chown www-data:www-data /var/www/html/wpmultienv/rewrites-env.conf /etc/apache2/rewrites/rewrites.conf
		/usr/sbin/apache2ctl graceful >/dev/null 2>&1
	fi
fi
