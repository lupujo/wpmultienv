#!/bin/bash

source /wpmultienv/env
WWWHOST=`cat /wpmultienv/wwwhost`
TAG="`date +%s`-$WWWHOST-`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`"

echo "Executing deploy script if available..."
if [ -f /var/www/html/wpmultienv/pre-publish.sh ]; then
bash /var/www/html/wpmultienv/pre-publish.sh
fi

echo "Dumping DB..."
rm -f /wpmultienv/sql.bz2 >/dev/null 2>&1
/usr/bin/mysqldump -uroot -p${SQLPASSROOT} -hdb wordpress | bzip2 > /wpmultienv/sql.bz2

echo "Adding wwwhost to webroot..."
echo $WWWHOST > /var/www/html/wpmultienv/wwwhost

echo "Compressing files..."
rm -f /wpmultienv/files.tbz2 >/dev/null 2>&1
cd /var/www/html/
tar cjvf /wpmultienv/files.tbz2 * >/dev/null 2>&1

echo "Uploading to S3..."
AWS_ACCESS_KEY_ID=$S3KEY AWS_SECRET_ACCESS_KEY=$S3SECRET aws s3 mv /wpmultienv/files.tbz2 s3://$S3BUCKET/$TAG-files.tbz2
AWS_ACCESS_KEY_ID=$S3KEY AWS_SECRET_ACCESS_KEY=$S3SECRET aws s3 mv /wpmultienv/sql.bz2 s3://$S3BUCKET/$TAG-sql.bz2

echo "Published wordpress with tag:"
echo "======================================================="
echo $TAG
echo "======================================================="
