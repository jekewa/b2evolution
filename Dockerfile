FROM jekewa/b2evolution:1.0.3

LABEL maintainer="jeff@swbyjeff.com"
LABEL description="Unmodified b2evolution.net software on minimal Apache HTTPD for blogging"

## Copy the files over the previous version

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

