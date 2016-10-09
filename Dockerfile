FROM ubuntu:16.04
MAINTAINER haiashinsu

ENV DEFAULT_LOCALE=en_NZ.UTF-8

# Install packages
RUN locale-gen ${DEFAULT_LOCALE} \
	  && export LANG=${DEFAULT_LOCALE} \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install curl git mcrypt wget rsync \
    && apt-get -y install apache2 php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-sqlite php7.0-bcmath \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install krb client and add Krb configuration
ADD config/krb5.conf /etc/krb5.conf
RUN apt-get update && apt-get -y install krb5-user libpam-krb5

# Enable mods
RUN a2enmod php7.0
RUN a2enmod rewrite

# Change PHP ini settings
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini

# Prepare Web root and Apache
RUN mkdir -p /www && \
    chown -R www-data:www-data /www

# Set up Apache environment variables
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid

# Remove default site, replace with own conf
RUN rm -f sites-enabled/000-default.conf
ADD config/apache.conf /etc/apache2/sites-enabled/000-default.conf

# Install Composer
RUN cd /tmp && curl -sS https://getcomposer.org/installer | php
RUN mv /tmp/composer.phar /usr/local/bin/composer

# Install Drupal Console
RUN cd /tmp && curl http://drupalconsole.com/installer -L -o drupal.phar
RUN mv /tmp/drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal
RUN drupal init

# Install Drush
RUN wget https://github.com/drush-ops/drush/releases/download/8.1.2/drush.phar \
  && php drush.phar core-status \
  && chmod +x drush.phar \
  && mv drush.phar /usr/local/bin/drush

EXPOSE 80

VOLUME ["/www", "/etc/apache2/vhost", /var/log/apache2"]
WORKDIR /www

# Start apache
CMD /usr/sbin/apache2ctl -D FOREGROUND
