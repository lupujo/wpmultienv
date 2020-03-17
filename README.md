# wpmultienv - Wordpress Multi Environment
Allows multiple Wordpress environments in a single server or in multiple servers with quick deployments between environments and tracked versions backed in AWS S3. \
Created by lupujo (jonathan.l@ongage.com)

# Usage examples:
* A single server with 1 dev env and 1 prod env
* A single server with 2 dev envs and 1 prod env
* 2 servers: prod (with 1 prod env) and dev (with 3 dev envs)
* 4 servers: prod (with 1 prod env), dev1 (with 1 dev env), dev2 (1 dev env), dev3 (1 dev env)

# Setup instructions:
* Clone into /usr/local/wpmultienv (or any other location, update PROJFOLDER in config file)
* To modify Wordpress or PHP versions, update the Dockerfile under wp/
* Create an S3 bucket and IAM user. Use an IAM policy that denies ListBucket for extra security.
* Add an IP per each environment to be used, update A records accordingly. Multiple IPs on a single instance were tested to be working under AWS EC2 by using "Secondary IPs".
* Make sure to configure all settings properly into config file (wpmultienv.conf) and generate randomized passwords for all password fields.
* Make sure to use a firewall or a security policy that limits access to selected IPs for web, sftp, ssh and any other needed port.
* If you need less than 3 ENVs, simply comment out or remove the unneccessary wordpress and db instances from docker-compose.yml. Keep the removed env(s) config variables in order to not break any script.
* Run init.sh before first launch from the project folder.
* Launch by running ```docker-compose up -d``` from the project folder.
* It's highly recommended to block web access to /wp-admin in the production environment and only use wp-admin under development environments.
* Optional: Create robots.txt-dev (usually deny all) and robots.txt-prod (usually allow) in Wordpress folder, those will be used automatically per environment.
* Optional: Update SSL certificate for envs you wish to use HTTPS:
  SSL Key: [Main Folder]/env[1-3]/ssl/ssl.key
  SSL Certificate & Chain: [Main Folder]/env[1-3]/ssl/ssl.cert
* Optional: Create robots.txt-dev (usually deny all) and robots.txt-prod (usually allow) in Wordpress folder in all envs, those will be used automatically per environment according to PRODWWWHOST config setting.

# Deployment between environments:
Publishing exports the entire wordpress website to S3 and returns a tag that can be used in the future to deploy to other environments in the same server or in different servers. Deploying overrides the local wordpress website with a version that was previously published to S3.
* Publish from any env to S3 by running:
```docker exec <container_name> /wpmultienv/publish.sh```
* Deploy from S3 to any env by running:
```docker exec <container_name> /wpmultienv/deploy.sh <tag>```

_Examples:_

* Publish from env1 to S3:
```docker exec wordpress-env1 /wpmultienv/publish.sh```
* Deploy a tag to env2 from S3:
```docker exec wordpress-env2 /wpmultienv/deploy.sh <tag>```

# TODO
* Add support for HTTPS
* Add support to get deployment commands without SSH access (API? Web based panel?)
* Add support to view apache/php logs without SSH access
* Implement support for email notifications
* Add checkpoints to all scripts to catch for errors and report properly
