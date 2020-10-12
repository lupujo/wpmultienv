#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No tag supplied"
    exit 1
fi

TAG=$1

source /wpmultienv/env
WWWHOST=`cat /wpmultienv/wwwhost`

rm -rf /wpmultienv/www /wpmultienv/files.tbz2 /wpmultienv/sql.bz2 /var/www/html-old
mkdir /wpmultienv/www

echo "Downloading files for $TAG..."
AWS_ACCESS_KEY_ID=$S3KEY AWS_SECRET_ACCESS_KEY=$S3SECRET aws s3 cp s3://$S3BUCKET/$TAG-files.tbz2 /wpmultienv/files.tbz2

echo "Downloading DB data for $TAG..."
AWS_ACCESS_KEY_ID=$S3KEY AWS_SECRET_ACCESS_KEY=$S3SECRET aws s3 cp s3://$S3BUCKET/$TAG-sql.bz2 /wpmultienv/sql.bz2

echo "Extracting files..."
tar xjvf /wpmultienv/files.tbz2 -C /wpmultienv/www/ >/dev/null 2>&1
chown -R www-data:www-data /wpmultienv/www
bzcat /wpmultienv/sql.bz2 > /wpmultienv/sql

echo "Getting original wwwhost..."
OLDWWWHOST=`cat /wpmultienv/www/wpmultienv/wwwhost`

echo "Removing undesired files..."
rm -rf /wpmultienv/www/wpmultienv/wwwhost /wpmultienv/www/wp-content/cache/* /wpmultienv/www/wp-content/cache-old/* /wpmultienv/www/wp-content/backupwordpress-* /wpmultienv/www/wp-content/mmr/* 

echo "Adding rewrite rules..."
if [ -f /var/www/html/wpmultienv/rewrites.conf ]; then
        cp -f /var/www/html/wpmultienv/rewrites.conf /etc/apache2/rewrites.conf
        perl -p -i -e "s/MAINURL/$WWWHOST/g" /etc/apache2/rewrites.conf
        /usr/sbin/apache2ctl graceful
fi

if [ "$WWWHOST" = "$PRODWWWHOST" ]; then
	echo "Detected deployment to production!"
        echo "Running sanity checks..."
        badresults1=`grep -R dev.-www /wpmultienv/www | grep -v window.location.host.split | wc -l`
        badresults2=`grep -R staging-www /wpmultienv/www | grep -v window.location.host.split | wc -l`
        if [ $badresults1 != 0 ] || [ $badresults2 != 0 ]; then
		echo "===================================================="
		echo "Website files being deployed to production expose"
		echo "development endpoints."
		echo "Aborting deployment of TAG $TAG to production."
		echo "===================================================="
		exit 1
	fi
	echo "Updating robots.txt for production..."
	cp -f /wpmultienv/www/wpmultienv/robots.txt-prod /wpmultienv/www/robots.txt
	echo "Updating htaccess for production..."
	cp -f /wpmultienv/www/wpmultienv/htaccess-prod /wpmultienv/www/.htaccess
else
	echo "Updating robots.txt for development..."
	cp -f /wpmultienv/www/wpmultienv/robots.txt-dev /wpmultienv/www/robots.txt
	echo "Updating htaccess for development..."
	cp -f /wpmultienv/www/wpmultienv/htaccess-dev /wpmultienv/www/.htaccess
fi

echo "Dropping local database..."
/usr/bin/mysql -uroot -p${SQLPASSROOT} -hdb -e"drop database wordpress;"
/usr/bin/mysql -uroot -p${SQLPASSROOT} -hdb -e"create database wordpress;"

echo "Importing new database..."
mysql -uroot -p${SQLPASSROOT} -hdb wordpress < /wpmultienv/sql

echo "Importing files..."
mkdir -p /var/www/html-old
mv /var/www/html/* /var/www/html-old/
mv /var/www/html/.* /var/www/html-old/ 2>/dev/null
mv /wpmultienv/www/* /var/www/html/
mv /wpmultienv/www/.* /var/www/html/ 2>/dev/null

echo "Running search and replace from $OLDWWWHOST to $WWWHOST via Migrate DB plugin"
wp migratedb find-replace --find=$OLDWWWHOST --replace=$WWWHOST

echo "Running search and replace from $OLDWWWHOST to $WWWHOST in database..."
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_options SET option_value = replace(option_value, '$OLDWWWHOST', '$WWWHOST') WHERE option_name = 'home' OR option_name = 'siteurl';"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_posts SET guid = replace(guid, '$OLDWWWHOST','$WWWHOST');"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_posts SET post_content = replace(post_content, '$OLDWWWHOST', '$WWWHOST');"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_postmeta SET meta_value = replace(meta_value, '$OLDWWWHOST', '$WWWHOST');"

echo "Clearing opcache if exists..."
/usr/local/bin/cachetool opcache:reset >/dev/null 2>&1

if [ "$WWWHOST" = "$PRODWWWHOST" ] || [ "$WWWHOST" = "$STAGEWWWHOST" ]; then
	echo "Executing post deployment script for production/staging if available..."
	if [ -f /var/www/html/wpmultienv/post-deploy-prod.sh ]; then
		bash /var/www/html/wpmultienv/post-deploy-prod.sh
	fi
else
	echo "Executing post deployment script for development if available..."
	if [ -f /var/www/html/wpmultienv/post-deploy-dev.sh ]; then
		bash /var/www/html/wpmultienv/post-deploy-dev.sh
	fi
fi

echo "Removing old files..."
rm -rf /var/www/html-old

#echo "Notifying..."
#echo "Corpweb was deployed from TAG $TAG into $WWWHOST (`hostname`)" | mail -s "Corpweb was deployed" $NOTIFYLIST

echo "Deployment of TAG $TAG completed into $WWWHOST (`hostname`)"
