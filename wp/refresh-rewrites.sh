#!/bin/bash
WWWHOST=`cat /wpmultienv/wwwhost`
if [ -f /var/www/html/wpmultienv/rewrites.conf ]; then
        cp -f /var/www/html/wpmultienv/rewrites.conf /var/www/html/wpmultienv/rewrites-env.conf
        perl -p -i -e "s/MAINURL/$WWWHOST/g" /var/www/html/wpmultienv/rewrites-env.conf
        cp -f /var/www/html/wpmultienv/rewrites-env.conf /etc/apache2/rewrites/rewrites.conf
	chown www-data:www-data /var/www/html/wpmultienv/rewrites-env.conf /etc/apache2/rewrites/rewrites.conf
	/usr/sbin/apache2ctl graceful >/dev/null 2>&1
fi
