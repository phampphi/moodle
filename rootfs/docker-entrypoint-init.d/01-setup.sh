#!/bin/sh
#
# Moodle configuration script
#
set -eo pipefail

# Check that the database is available
echo "Waiting for $DB_HOST:${DB_PORT:-3306} to be ready"
while ! nc -w 1 $DB_HOST ${DB_PORT:-3306}; do
    # Show some progress
    echo -n '.';
    sleep 1;
done
echo "database is ready"

# Check if the config.php file exists
if [ ! -f /var/www/html/config.php ]; then
    echo "Generating config.php file..."
    ENV_VAR='var' php -d max_input_vars=1000 /var/www/html/admin/cli/install.php \
        --lang=${MOODLE_LANGUAGE:-en} \
        --wwwroot=${SITE_URL:-http://127.0.0.1:8080} \
        --dataroot=${DATAROOT:-/var/www/moodledata/} \
        --dbtype=${DB_TYPE:-mysqli} \
        --dbhost=$DB_HOST \
        --dbname=$DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASS \
        --dbport=${DB_PORT:-3306} \
        --prefix=${DB_PREFIX:-mdl_} \
        --fullname="${MOODLE_SITE_NAME:-Elearning Platform}" \
        --shortname="${MOODLE_SITE_SHORT_NAME:-Elearning Platform}" \
        --adminuser=${MOODLE_USERNAME:-admin} \
        --adminpass=$MOODLE_PASSWORD \
        --adminemail=$MOODLE_EMAIL \
        --non-interactive \
        --agree-license \
        --skip-database

    sed -i '/require_once/i $CFG->localcachedir="/var/www/html/localcache";' /var/www/html/config.php

    if [ "$SSLPROXY" = 'true' ]; then
        sed -i '/require_once/i $CFG->sslproxy=true;' /var/www/html/config.php
    fi

    if [[ -n "${MOODLE_REDIS_HOST}" ]]; then
        sed -i '/require_once/i $CFG->session_handler_class = "\core\session\redis"' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_host = "${MOODLE_REDIS_HOST}"' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_port = 6379' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_database = 0' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_auth = "${MOODLE_REDIS_PASSWORD}"' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_prefix = "${MOODLE_REDIS_PREFIX:-}"' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_acquire_lock_timeout = 120' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_acquire_lock_retry = 100' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_lock_expire = 7200' /var/www/html/config.php
        sed -i '/require_once/i $CFG->session_redis_serializer_use_igbinary = false' /var/www/html/config.php
    fi
fi

# Check if the database is already installed
if php -d max_input_vars=1000 /var/www/html/admin/cli/isinstalled.php ; then
    echo "Installing database..."
    php -d max_input_vars=1000 /var/www/html/admin/cli/install_database.php \
        --lang=${MOODLE_LANGUAGE:-en} \
        --adminuser=${MOODLE_USERNAME:-admin} \
        --adminpass=$MOODLE_PASSWORD \
        --adminemail=$MOODLE_EMAIL \
        --fullname="${MOODLE_SITE_NAME:-Elearning Platform}" \
        --shortname="${MOODLE_SITE_SHORT_NAME:-Elearning Platform}" \
        --agree-license
else
    echo "Database installed."
fi

if [[ -n "${DISABLED_PLUGINS}" ]]; then
    echo "Disabling plugins: ${DISABLED_PLUGINS}"
    php /var/www/html/admin/cli/uninstall_plugins.php  --plugins=${DISABLED_PLUGINS} --run
fi

if [[ -n "${OLD_SITE_URL}" && "${OLD_SITE_URL}" != "${SITE_URL}" ]]; then
    echo "Change SiteURL: ${OLD_SITE_URL} --> ${SITE_URL}"
    php /var/www/html/admin/tool/replace/cli/replace.php --search=${OLD_SITE_URL} --replace=${SITE_URL} --non-interactive
fi
