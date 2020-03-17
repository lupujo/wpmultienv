# wpmultienv - Wordpress Multi Environment
Allows multiple Wordpress environments for a development workflow on a single server or on multiple servers with 1-click automated deployments between environments and tracked version history backed in AWS S3.

Unlike some existing solutions which use Wordpress migration plugins, patching PHP code or using multisite features for hosting multiple sites on a single Wordpress installation, this solution provides complete separation between each environment while Wordpress is completely unaware of it being used as part of a group of multiple syncing environments.
https://github.com/lupujo/wpmultienv \
jonathan.l@ongage.com

# Examples for supported use-cases:
* A single machine with 1 dev env and 1 production env.
* A single machine with 3 envs: dev, staging and production.
* A single machine with 1 production env and a developer local PC running the dev env.
* 2 machines: prod (with 1 prod env) and dev (with 3 dev envs)
* 4 machines: prod (with 1 prod env), dev1 (with 1 dev env), dev2 (2nd dev env), dev3 (3rd dev env)
* Any other desired combination.

# Setup instructions:
* Clone project into /usr/local/wpmultienv (or any other location, update PROJFOLDER in the config file)
* If you wish to modify the Wordpress or PHP versions, update the desired versions in the Dockerfile under wp/
* Create an S3 bucket and an IAM user. Use an IAM policy that allows access only to that bucket and denies ListBucket for extra security.
* According to the number of environments you wish to run, add an IP per each one to the server, create A records for new hostnames and update the config file with the IP(s). For environments you don't need, use a 127.0.0.X IP. Multiple IPs on a single instance were tested to be working with AWS EC2 by using "Secondary IPs". 
* Make sure to configure all settings properly into config file (wpmultienv.conf) per comments and make sure to generate strong *different* passwords for all relevant password fields in config file.
* Use a firewall or a security policy to limit access to selected IPs (if desired) for the SFTP port (TCP/2222), Host SSH port (TCP/22) and the HTTP ports (TCP/80, TCP/443).
* If you need less than 3 ENVs on a single server, simply configure a 127.0.0.X IP in the config file for the ENV you don't wish to use. If you also wish to stop launching it although it doesn't do anything you can simply comment out or remove the env's wordpress and db containers from docker-compose.yml. Keep the removed env(s) config variables in order to not break any script.
* Run init.sh before first launch from the project folder.
* Launch by running ```docker-compose up -d``` from the project folder.
* It's highly recommended to block web access to /wp-admin in the production environment and only use wp-admin under development environments.
* Optional: Update SSL key and certificate for envs you wish to use HTTPS:
** SSL Key: [Main Folder]/env[1-3]/ssl/ssl.key
** SSL Certificate & Chain: [Main Folder]/env[1-3]/ssl/ssl.cert
* Optional: Create robots.txt-dev (usually deny all) and robots.txt-prod (usually allow all) per your needs in the Wordpress webroot folder, those will be deployed automatically depending on environment.

# How it works
* The action of "Publish" on an environment exports the entire wordpress website to S3 and returns a version tag that can be used in the future to deploy to other environments on the same server or on different servers. \
Publish from any env to S3 by running: \
```docker exec wordpress-<env> /wpmultienv/publish.sh```
* The action of "Deploy" on an environment requires a tag to be provided. It destroys the existing wordpress website and overrides it with a version from S3 that was previously published using the provided version tag. \
Deploy from S3 to any env by running: \
```docker exec wordpress-<env> /wpmultienv/deploy.sh <tag>```

_Examples:_

* Publish from env1 to S3: \
```docker exec wordpress-env1 /wpmultienv/publish.sh```
* Deploy from S3 to env2 tag _111111111-dev.site.com-aaaaaaaaaaaa_: \
```docker exec wordpress-env2 /wpmultienv/deploy.sh 111111111-dev.site.com-aaaaaaaaaaaa```

# TODO
* Add support for HTTPS
* Add support to get deployment commands without SSH access (API? Web based panel?)
* Add support to view apache/php logs without SSH access
* Implement support for email notifications
* Add checkpoints to all scripts to catch for errors and report properly
