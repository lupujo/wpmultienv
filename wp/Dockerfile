FROM wordpress:5.3.2-php7.3-apache
ARG WWWDATA_UID
ARG WWWDATA_GID
ARG WWWHOST
RUN usermod -u ${WWWDATA_UID} www-data
RUN groupmod -g ${WWWDATA_GID} www-data
RUN apt-get -y update && apt-get -y install mariadb-client awscli mailutils less
RUN mkdir -p /wpmultienv
RUN chown -R www-data:www-data /wpmultienv /var/www
RUN echo ${WWWHOST} > /wpmultienv/wwwhost
ADD ./publish.sh /wpmultienv/publish.sh
ADD ./deploy.sh /wpmultienv/deploy.sh
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod 755 /wpmultienv/publish.sh /wpmultienv/deploy.sh /usr/local/bin/wp
RUN ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
RUN ln -s /etc/apache2/mods-available/ssl.conf /etc/apache2/mods-enabled/ssl.conf                  
RUN ln -s /etc/apache2/mods-available/ssl.load /etc/apache2/mods-enabled/ssl.load
RUN ln -s /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/headers.load
RUN echo "Header set Access-Control-Allow-Origin \"*\"" >> /etc/apache2/conf-available/security.conf
RUN ln -s /etc/apache2/mods-available/socache_shmcb.load /etc/apache2/mods-enabled/socache_shmcb.load
RUN perl -p -i -e 's/SSLCertificate[File|Key].*//' /etc/apache2/sites-available/default-ssl.conf
RUN perl -p -i -e 's/SSLEngine on/SSLEngine on\n\t\tSSLCertificateFile \/etc\/apache2\/ssl\/ssl.cert\n\t\tSSLCertificateKeyFile \/etc\/apache2\/ssl\/ssl.key\n\t\tSSLCertificateChainFile \/etc\/apache2\/ssl\/ssl.cert/' /etc/apache2/sites-available/default-ssl.conf
RUN perl -p -i -e 's/SSLProtocol all -SSLv3/SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1/' /etc/apache2/mods-available/ssl.conf
RUN perl -p -i -e 's/\#SSLHonorCipherOrder on/SSLHonorCipherOrder on/' /etc/apache2/mods-available/ssl.conf
RUN perl -p -i -e 's/DEFLATE application\/xml/DEFLATE application\/xml font\/ttf image\/x-icon image\/vnd.microsoft.icon/' /etc/apache2/mods-available/deflate.conf
RUN perl -p -i -e 's/\#Include conf-available\/serve-cgi-bin.conf/IncludeOptional \/etc\/apache2\/rewrites.conf/' /etc/apache2/sites-available/000-default.conf
RUN perl -p -i -e 's/\#Include conf-available\/serve-cgi-bin.conf/IncludeOptional \/etc\/apache2\/rewrites.conf/' /etc/apache2/sites-available/default-ssl.conf
