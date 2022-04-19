FROM ubuntu:hirsute

LABEL maintainer="jeff@swbyjeff.com"
LABEL description="Unmodified b2evolution.net software on minimal Apache HTTPD for blogging"

EXPOSE 80
EXPOSE 443

ENV DB_USER=user DB_PASSWORD=password DB_NAME=b2evolution DB_HOST=mysql
ENV BASE_URL="http://localhost/" ADMIN_EMAIL="admin@localhost"
ENV SERVER_NAME=localhost PHP_TIMEZONE=UTC 
ENV LETSENCRYPT_CERTNAME=localhost

HEALTHCHECK --start-period=15s --timeout=1s CMD curl -kf http://localhost/monitor.txt || exit 1

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y apt-utils curl locales apache2 php7.4-curl php7.4-gd libapache2-mod-php7.4 php-apcu php-imagick php-imap php-mbstring php-mysql php-xml php-zip \
    && apt-get upgrade -y \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Add b2evolution software
COPY b2evolution /opt/b2evolution

# Default .htaccess files
RUN find /opt/b2evolution -name sample.htaccess -execdir cp {} .htaccess \;

# Add custom configs
COPY monitor.txt /opt/b2evolution
COPY conf /opt/b2evolution/conf
COPY skins /opt/b2evolution/skins
COPY plugins /opt/b2evolution/plugins

RUN chmod -R go+w /opt/b2evolution/_cache /opt/b2evolution/media && chown -R www-data:www-data /opt/b2evolution

# Default upgrade policy
COPY b2evolution/conf/upgrade_policy_sample.conf opt/b2evolution/conf/upgrade_policy.conf

# Run scheduled maintenance (every minute by default)
COPY b2evolution.cron /etc/cron.d/

# Configure Apache
COPY sites-available /etc/apache2/sites-available

RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && a2enmod remoteip rewrite speling ssl \
    && a2dissite 000-default \
    && a2ensite b2evolution

VOLUME /etc/letsencrypt /opt/b2evolution/_cache /opt/b2evolution/media

CMD ["apachectl","-D","FOREGROUND"]
