#!/bin/bash

source .env
mkdir -p $MAINFOLDER/env1/db
mkdir -p $MAINFOLDER/env1/www
mkdir -p $MAINFOLDER/env2/db
mkdir -p $MAINFOLDER/env2/www
mkdir -p $MAINFOLDER/env3/db
mkdir -p $MAINFOLDER/env3/www
mkdir -p $MAINFOLDER/sftpdata
chown -R $HOSTUID:$HOSTGID /$MAINFOLDER/env1 /$MAINFOLDER/env2 /$MAINFOLDER/env3 /$MAINFOLDER/sftpdata
chown -R $ENV1UID:$ENV1GID /$MAINFOLDER/env1/www
chown -R $ENV2UID:$ENV2GID /$MAINFOLDER/env2/www
chown -R $ENV3UID:$ENV3GID /$MAINFOLDER/env3/www
chown -R 999:999 $MAINFOLDER/env1/db
chown -R 999:999 $MAINFOLDER/env2/db
chown -R 999:999 $MAINFOLDER/env3/db
if [ ! -f "$MAINFOLDER/env1/ssl/ssl.key" ]; then
	mkdir -p $MAINFOLDER/env1/ssl
	cp ssl/* $MAINFOLDER/env1/ssl/
fi
if [ ! -f "$MAINFOLDER/env2/ssl/ssl.key" ]; then
	mkdir -p $MAINFOLDER/env2/ssl
	cp ssl/* $MAINFOLDER/env2/ssl/
fi
if [ ! -f "$MAINFOLDER/env3/ssl/ssl.key" ]; then
	mkdir -p $MAINFOLDER/env3/ssl
	cp ssl/* $MAINFOLDER/env3/ssl/
fi
