# nc-installer

Nc-installer.sh is an easy to use Nextcloud installer that installs on Ubuntu in about 5 minutes.

Simply run the script as root or with sudo, enter your desired usernamd and password, then let nc-installer.sh do the rest.

When it's finished, set up a cron job for www-data with the following command: 
`crontab -u www-data and enter */5 * * * * php -f /var/www/nextcloud/cron.php`

Save and restart cron with `systemctl restart cron.service`

Consider setting up HTTPS if you will be accessing Nexcloud outside of your private network.
