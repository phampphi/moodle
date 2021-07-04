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
        --wwwroot=${SITE_URL:-http://localhost:8080} \
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

    if [ "$SSLPROXY" = 'true' ]; then
        sed -i '/require_once/i $CFG->sslproxy=true;' /var/www/html/config.php
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