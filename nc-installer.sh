#!/bin/bash

read -p "Please enter Nextcloud admin username: " DBUSER
read -p "Enter password for ${DBUSER}: " DBPASS

UVER=$(lsb_release -sr | sed 's/\.//')

if [ $UVER -ge 2010 ]
then
PHPVER=8.3
else
PHPVER=7.4
fi



apt-get update

apt-get clean

apt-get -y install unzip nginx

(apt-get -y install mysql-server php$PHPVER  php$PHPVER-common \
php$PHPVER-fpm php$PHPVER-curl php$PHPVER-mysql php$PHPVER-gd php$PHPVER-opcache php$PHPVER-xml php$PHPVER-cli \
php$PHPVER-zip php$PHPVER-mbstring php$PHPVER-imagick php$PHPVER-intl php$PHPVER-gmp php$PHPVER-bcmath php$PHPVER-apcu \
libmagickcore-6.q16-6-extra redis-server php-redis --fix-missing) &

wget https://download.nextcloud.com/server/releases/latest.zip
unzip -q latest.zip
rm latest.zip
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud
systemctl enable --now nginx



wait

systemctl enable --now php${PHPVER}-fpm

systemctl enable --now mysql

mysql -e "CREATE DATABASE nextcloud;"
mysql -e "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';"
mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* to '${DBUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud" \
--database-user "${DBUSER}" --database-pass "${DBPASS}" --admin-user "${DBUSER}" \
--admin-pass "${DBPASS}"

sudo -u www-data php /var/www/nextcloud/occ background:cron

sudo -u www-data php /var/www/nextcloud/occ app:install calendar
sudo -u www-data php /var/www/nextcloud/occ app:install notes
sudo -u www-data php /var/www/nextcloud/occ app:install mail
sudo -u www-data php /var/www/nextcloud/occ app:install side_menu

systemctl enable --now redis-server

sed -i 's/# unixsocket /unixsocket /g' /etc/redis/redis.conf
sed -i 's/# unixsocketperm 700/unixsocketperm 770/g' /etc/redis/redis.conf

systemctl restart redis-server.service
usermod -aG redis www-data

echo -e "apc.enable_cli=1" >> /etc/php/${PHPVER}/cli/php.ini
sed -i "0,/localhost/{s/localhost/$(dig +short `hostname -f`)/g}" /var/www/nextcloud/config/config.php
sed -i '$ d' /var/www/nextcloud/config/config.php
tee -a /var/www/nextcloud/config/config.php << endmsg
  'default_phone_region' => 'US',
  'memcache.local' => '\\\OC\\\Memcache\\\APCu',
  'memcache.distributed' => '\\\OC\\\Memcache\\\Redis',
  'memcache.locking' => '\\\OC\\\Memcache\\\Redis',
  'filelocking.enabled' => 'true',
  'redis' =>
  array (
    'host' => '/run/redis/redis-server.sock',
    'port' => 0,
    'timeout' => 0.0,
  ),
);
endmsg

sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair --include-expensive

sed -i 's/memory\_limit \= 128M/memory\_limit \= 512M/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/max_file_uploads = 20/max_file_uploads = 200/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=16/g" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=16/g" /etc/php/${PHPVER}/cli/php.ini
sed -i 's/;env/env/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf

systemctl restart php${PHPVER}-fpm

while read -r -u 9 user; do
    {
    if [ "$user" == "www-data" ]
    then
        crontab -l -u "$user"
        printf '%s\n' '*/5 * * * * php -f /var/www/nextcloud/cron.php'
    fi
    } | crontab -u "$user" -
done 9< <(getent passwd | cut -d: -f1)

systemctl restart cron.service

DBPASS=
DBUSER=
