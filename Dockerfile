FROM php:7.3.16-apache-buster

MAINTAINER David Hong

COPY ./config/php.ini /usr/local/etc/php/php.ini
COPY ./htdocs/ /var/www/html/
COPY ./config/vhost.conf /etc/apache2/sites-available/000-default.conf

RUN usermod -u 999 www-data && \
    groupmod -g 999 www-data

RUN apt update
RUN apt -y install apt-transport-https ca-certificates git vim unzip curl wget bzip2 pwgen apt-file apt-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev
RUN apt-get install -y re2c libmcrypt-dev libzip-dev libssl-dev libtidy-dev libpng16-16 libpng-dev libjpeg-dev libbz2-dev libcurl4-gnutls-dev libxml2 libxml2-dev librecode-dev libicu-dev
RUN apt-get install -y libc-client-dev libkrb5-dev
RUN rm -rf /var/lib/apt/lists/*

# install PHP PEAR extensions
#RUN pear install channel://pear.php.net/HTTP_WebDAV_Server-1.0.0RC8 \
#	&& pear install Auth_SASL \
#	&& pear install Net_IMAP \
#	&& pear install XML_Feed_Parser \
#	&& pear install pear install Net_Sieve

# Pear mail
RUN curl -s -o /tmp/go-pear.phar http://pear.php.net/go-pear.phar && \
    echo '/usr/bin/php /tmp/go-pear.phar "$@"' > /usr/bin/pear && \
    chmod +x /usr/bin/pear && \
    pear install mail Net_SMTP

# PHP extensions
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/lib
RUN docker-php-ext-configure imap --with-imap-ssl --with-kerberos

RUN apt-get update \
	&& docker-php-ext-install gd mysqli pdo_mysql zip imap bz2 mbstring curl bcmath xml zip recode tidy xmlrpc intl \
	&& rm -rf /var/lib/apt/lists/*


#RUN docker-php-ext-install pear libapache2 mysql mbstring curl dev bz2 gd bcmath xml zip imagick fpm recode tidy xmlrpc intl
#RUN docker-php-ext-install mbstring curl bz2 gd bcmath xml zip recode tidy xmlrpc intl
# Enable apache mods
RUN a2enmod php7 rewrite headers proxy proxy_ajp proxy_http rewrite deflate filter expires ssl headers proxy_balancer proxy_connect proxy_html

# Suppress FQDN message
 #RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf && \ a2enconf fqdn

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /var/www/html

# Set timezone
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 80
