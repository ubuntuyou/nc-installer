# nc-installer

Nc-installer.sh is an easy to use Nextcloud installer that installs on Ubuntu in about 5 minutes.

Simply run the script as root or with sudo, enter your desired username and password, then let nc-installer.sh do the rest.

```
# wget https://github.com/ubuntuyou/nc-installer/blob/main/nc-installer.sh

# chmod a+x nc-installer.sh

# ./nc-installer.sh
```
When the script finishes, point your browser at http://<IP-OF-NEXTCLOUD-MACHINE> and login with the username and password that you entered.
Consider setting up HTTPS if you will be accessing Nexcloud outside of your private network. Nginx Proxy Manager makes this extremely easy to setup.

The script was tested to run in an LXC container in a Proxmox virtual environment.
