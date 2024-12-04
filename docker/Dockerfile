FROM php:8.3-apache-bookworm

# Install system dependencies
RUN apt-get update; apt-get install jq mariadb-client apt-utils -y; 
#libcurl4-openssl-dev zlib 

#Install php dependencies
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions gd mysqli pdo_mysql intl zip bcmath
#RUN docker-php-ext-install curl gd mysqli pdo_mysql xml mbstring intl zip bcmath pdo

#Enable modules, settings, and default of SSL in Apache
RUN a2dismod status; a2enmod rewrite; a2enmod ssl; a2enmod headers;

#Installation of MONARC
RUN set -ex; \
    PATH_TO_MONARC='/var/lib/monarc/fo'; \
    PATH_TO_MONARC_DATA='/var/lib/monarc/fo-data'; \
    MONARC_VERSION=$(curl --silent -H 'Content-Type: application/json' https://api.github.com/repos/monarc-project/MonarcAppFO/releases/latest | jq  -r '.tag_name'); \
    MONARCFO_RELEASE_URL="https://github.com/monarc-project/MonarcAppFO/releases/download/$MONARC_VERSION/MonarcAppFO-$MONARC_VERSION.tar.gz"; \
    \
    mkdir -p /var/lib/monarc/releases/; \
    curl -sL $MONARCFO_RELEASE_URL -o /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL`; \
    mkdir /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'`; \
    tar -xzf /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL` -C /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'`; \
    ln -s /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'` $PATH_TO_MONARC; \
    \
    mkdir -p $PATH_TO_MONARC_DATA/cache $PATH_TO_MONARC_DATA/DoctrineORMModule/Proxy $PATH_TO_MONARC_DATA/LazyServices/Proxy $PATH_TO_MONARC_DATA/import/files; \
    ln -s $PATH_TO_MONARC_DATA $PATH_TO_MONARC/data

#Change owner
RUN set -ex; chown -R www-data:www-data /var/lib/monarc;

VOLUME /var/lib/monarc/fo-data

# Set document root
ENV APACHE_DOCUMENT_ROOT /var/lib/monarc/fo/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

#PHP Setting
RUN { \
        echo 'upload_max_filesize = 200M'; \
        echo 'post_max_size = 50M'; \
        echo 'max_execution_time = 100'; \
        echo 'max_input_time = 223'; \
        echo 'memory_limit = 2048M'; \
        echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE & ~E_WARNING'; \
    } > "${PHP_INI_DIR}/conf.d/monarc.ini";

# 
COPY docker/init.sh /init.sh
RUN chmod +x /init.sh

COPY docker/run.sh /run.sh
RUN chmod +x /run.sh

CMD if [ ! -f /tmp/initialized ]; then /init.sh && touch /tmp/initialized; fi && /run.sh
