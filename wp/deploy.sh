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
OLDWWWHOST=`cat /wpmultienv/www/wwwhost`

echo "Removing undesired files..."
rm -rf /wpmultienv/www/wwwhost /wpmultienv/www/wp-content/cache/* /wp-content/cache-old/* /wp-content/backupwordpress-* /wp-content/mmr/* 

if [ "$WWWHOST" = "$PRODWWWHOST" ]; then
	echo "Detected deployment to production!"
        echo "Running sanity checks..."
	badresults=`grep -R dev.-www /wpmultienv/www | grep -v window.location.host.split | wc -l`
	if [ $badresults != 0 ]; then
		echo "===================================================="
		echo "Website files being deployed to production expose"
		echo "development endpoints."
		echo "Aborting deployment of TAG $TAG to production."
		echo "===================================================="
		exit 1
	fi
	echo "Updating robots.txt for production..."
	mv -f /wpmultienv/www/robots.txt-prod /wpmultienv/www/robots.txt
	echo "Updating htaccess for production..."
	mv -f /wpmultienv/www/htaccess-prod /wpmultienv/www/.htaccess
else
	echo "Updating robots.txt for development..."
	mv -f /wpmultienv/www/robots.txt-dev /wpmultienv/www/robots.txt
	echo "Updating htaccess for development..."
	mv -f /wpmultienv/www/htaccess-dev /wpmultienv/www/.htaccess
fi

echo "Dropping local database..."
/usr/bin/mysql -uroot -p${SQLPASSROOT} -hdb -e"drop database wordpress;"
/usr/bin/mysql -uroot -p${SQLPASSROOT} -hdb -e"create database wordpress;"

echo "Importing new database..."
mysql -uroot -p${SQLPASSROOT} -hdb wordpress < /wpmultienv/sql

echo "Running search and replace from $OLDWWWHOST to $WWWHOST in database..."
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_options SET option_value = replace(option_value, '$OLDWWWHOST', '$WWWHOST') WHERE option_name = 'home' OR option_name = 'siteurl';"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_posts SET guid = replace(guid, '$OLDWWWHOST','$WWWHOST');"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_posts SET post_content = replace(post_content, '$OLDWWWHOST', '$WWWHOST');"
mysql -uroot -p${SQLPASSROOT} wordpress -hdb -e"UPDATE wp_postmeta SET meta_value = replace(meta_value, '$OLDWWWHOST', '$WWWHOST');"

echo "Importing files..."
mkdir -p /var/www/html-old
mv /var/www/html/* /var/www/html-old/
mv /wpmultienv/www/* /var/www/html/

echo "Clearing opcache if exists..."
/usr/local/bin/cachetool opcache:reset >/dev/null 2>&1

echo "Executing deploy script if available..."
if [ -f /var/www/html/wpmultienv.deploy ]; then
bash /var/www/html/wpmultienv.deploy
fi

echo "Removing old files..."
rm -rf /var/www/html-old

#echo "Notifying..."
#echo "Corpweb was deployed from TAG $TAG into $WWWHOST (`hostname`)" | mail -s "Corpweb was deployed" $NOTIFYLIST

echo "Deployment of TAG $TAG completed into $WWWHOST (`hostname`)"
