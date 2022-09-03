#!/bin/bash

read -p "Please enter Nextcloud admin username: " DBUSER
read -p "Enter password for ${DBUSER}: " DBPASS

UVER=$(lsb_release -sr | sed 's/\.//')

if [ $UVER -ge 2010 ]
then
PHPVER=8.1
else
PHPVER=7.4
fi

apt-get update && apt-get clean && apt-get -y install unzip nginx mysql-server php$PHPVER  php$PHPVER-common \
php$PHPVER-fpm php$PHPVER-curl php$PHPVER-mysql php$PHPVER-gd php$PHPVER-opcache php$PHPVER-xml php$PHPVER-cli \
php$PHPVER-zip php$PHPVER-mbstring php$PHPVER-imagick php$PHPVER-intl php$PHPVER-gmp php$PHPVER-bcmath php$PHPVER-apcu \
libmagickcore-6.q16-6-extra --fix-missing

systemctl enable --now php${PHPVER}-fpm

systemctl enable --now mysql

mysql -e "CREATE DATABASE nextcloud;"
mysql -e "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';"
mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* to '${DBUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

systemctl enable --now nginx

wget https://download.nextcloud.com/server/releases/latest.zip
unzip -q latest.zip
rm latest.zip
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/nextcloud << 'endmsg'
upstream php-handler {
        server unix:/var/run/php/phpREPLACEME-fpm.sock;
}

server {
        listen 80;
        server_name _;

        root /var/www/nextcloud;
        index index.php index.html /index.php$request_uri;

        # Limit Upload Size
        client_max_body_size 512M;
        fastcgi_buffers 64 4K;

        # Gzip Compression
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        # Recommended Security Headers
        add_header Referrer-Policy                      "no-referrer"   always;
        add_header X-Content-Type-Options               "nosniff"       always;
        add_header X-Download-Options                   "noopen"        always;
        add_header X-Frame-Options                      "SAMEORIGIN"    always;
        add_header X-Permitted-Cross-Domain-Policies    "none"          always;
        add_header X-Robots-Tag                         "none"          always;
        add_header X-XSS-Protection                     "1; mode=block" always;
        fastcgi_hide_header X-Powered-By;

        # Recommended Hidden Paths
        location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
        location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)              { return 404; }

        location ~ \.php(?:$|/) {
                fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
                set $path_info $fastcgi_path_info;
                try_files $fastcgi_script_name =404;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $path_info;
                fastcgi_param modHeadersAvailable true;
                fastcgi_param front_controller_active true;
                fastcgi_pass php-handler;
                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
                include fastcgi_params;
                proxy_connect_timeout 600s;
                proxy_send_timeout 600s;
                proxy_read_timeout 600s;
                fastcgi_send_timeout 600s;
                fastcgi_read_timeout 600s;
        }

        # Regex exception for './well-known
        location ^~ /.well-known {
                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }
                location ^~ /.well-known        { return 301 /index.php$uri; }

                try_files $uri $uri/ =404;
        }

        # Cache-Control on Assets
        location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
                try_files $uri /index.php$request_uri;
                add_header Cache-Control "public, max-age=15778463";
                expires 6M;
        }

        location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)$ {
                try_files $uri /index.php$request_uri;
        }

        location / {
                try_files $uri $uri/ /index.php$request_uri;
        }
}
endmsg

sed -i "s/REPLACEME/$PHPVER/g" /etc/nginx/sites-available/nextcloud

ln -s /etc/nginx/sites-available/nextcloud -t /etc/nginx/sites-enabled/

systemctl restart nginx

sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud" \
--database-user "${DBUSER}" --database-pass "${DBPASS}" --admin-user "${DBUSER}" \
--admin-pass "${DBPASS}"

sudo -u www-data php /var/www/nextcloud/occ background:cron

#!/bin/bash

read -p "Please enter Nextcloud admin username: " DBUSER
read -p "Enter password for ${DBUSER}: " DBPASS

UVER=$(lsb_release -sr | sed 's/\.//')

if [ $UVER -ge 2010 ]
then
PHPVER=8.1
else
PHPVER=7.4
fi

apt-get update && apt-get clean && apt-get -y install unzip nginx mysql-server php$PHPVER  php$PHPVER-common \
php$PHPVER-fpm php$PHPVER-curl php$PHPVER-mysql php$PHPVER-gd php$PHPVER-opcache php$PHPVER-xml php$PHPVER-cli \
php$PHPVER-zip php$PHPVER-mbstring php$PHPVER-imagick php$PHPVER-intl php$PHPVER-gmp php$PHPVER-bcmath php$PHPVER-apcu \
libmagickcore-6.q16-6-extra --fix-missing

systemctl enable --now php${PHPVER}-fpm

systemctl enable --now mysql

mysql -e "CREATE DATABASE nextcloud;"
mysql -e "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';"
mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* to '${DBUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

systemctl enable --now nginx

wget https://download.nextcloud.com/server/releases/latest.zip
unzip -q latest.zip
rm latest.zip
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/nextcloud << 'endmsg'
upstream php-handler {
        server unix:/var/run/php/phpREPLACEME-fpm.sock;
}

server {
        listen 80;
        server_name _;

        root /var/www/nextcloud;
        index index.php index.html /index.php$request_uri;

        # Limit Upload Size
        client_max_body_size 512M;
        fastcgi_buffers 64 4K;

        # Gzip Compression
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        # Recommended Security Headers
        add_header Referrer-Policy                      "no-referrer"   always;
        add_header X-Content-Type-Options               "nosniff"       always;
        add_header X-Download-Options                   "noopen"        always;
        add_header X-Frame-Options                      "SAMEORIGIN"    always;
        add_header X-Permitted-Cross-Domain-Policies    "none"          always;
        add_header X-Robots-Tag                         "none"          always;
        add_header X-XSS-Protection                     "1; mode=block" always;
        fastcgi_hide_header X-Powered-By;

        # Recommended Hidden Paths
        location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
        location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)              { return 404; }

        location ~ \.php(?:$|/) {
                fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
                set $path_info $fastcgi_path_info;
                try_files $fastcgi_script_name =404;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $path_info;
                fastcgi_param modHeadersAvailable true;
                fastcgi_param front_controller_active true;
                fastcgi_pass php-handler;
                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
                include fastcgi_params;
                proxy_connect_timeout 600s;
                proxy_send_timeout 600s;
                proxy_read_timeout 600s;
                fastcgi_send_timeout 600s;
                fastcgi_read_timeout 600s;
        }

        # Regex exception for './well-known
        location ^~ /.well-known {
                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }
                location ^~ /.well-known        { return 301 /index.php$uri; }

                try_files $uri $uri/ =404;
        }

        # Cache-Control on Assets
        location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
                try_files $uri /index.php$request_uri;
                add_header Cache-Control "public, max-age=15778463";
                expires 6M;
        }

        location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)$ {
                try_files $uri /index.php$request_uri;
        }

        location / {
                try_files $uri $uri/ /index.php$request_uri;
        }
}
endmsg

sed -i "s/REPLACEME/$PHPVER/g" /etc/nginx/sites-available/nextcloud

ln -s /etc/nginx/sites-available/nextcloud -t /etc/nginx/sites-enabled/

systemctl restart nginx

sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud" \
--database-user "${DBUSER}" --database-pass "${DBPASS}" --admin-user "${DBUSER}" \
--admin-pass "${DBPASS}"

sudo -u www-data php /var/www/nextcloud/occ background:cron

apt-get clean
apt-get -y install redis-server php-redis --fix-missing

systemctl enable --now redis-server

sed -i 's/# unixsocket /unixsocket /g' /etc/redis/redis.conf
sed -i 's/# unixsocketperm 700/unixsocketperm 770/g' /etc/redis/redis.conf

systemctl restart redis-server.service
usermod -aG redis www-data

echo -e "apc.enable_cli=1" >> /etc/php/${PHPVER}/cli/php.ini

sed -i "0,/localhost/{s/localhost/$(hostname -i)/g}" /var/www/nextcloud/config/config.php
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

sed -i 's/memory\_limit \= 128M/memory\_limit \= 512M/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/max_file_uploads = 20/max_file_uploads = 200/g' /etc/php/${PHPVER}/fpm/php.ini

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

apt-get clean
apt-get -y install redis-server php-redis --fix-missing

systemctl enable --now redis-server

sed -i 's/# unixsocket /unixsocket /g' /etc/redis/redis.conf
sed -i 's/# unixsocketperm 700/unixsocketperm 770/g' /etc/redis/redis.conf

systemctl restart redis-server.service
usermod -aG redis www-data

echo -e "apc.enable_cli=1" >> /etc/php/${PHPVER}/cli/php.ini

sed -i "0,/localhost/{s/localhost/$(hostname -i)/g}" /var/www/nextcloud/config/config.php
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

sed -i 's/memory\_limit \= 128M/memory\_limit \= 512M/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/${PHPVER}/fpm/php.ini
sed -i 's/max_file_uploads = 20/max_file_uploads = 200/g' /etc/php/${PHPVER}/fpm/php.ini

sed -i 's/;env/env/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf

systemctl restart php${PHPVER}-fpm

DBPASS=
DBUSER=
