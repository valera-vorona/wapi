# wapi
REST API Scriptless Web Framework

### You may need to preinstall (Debian/Ubuntu):
sudo apt install postgresql ansible fcgiwrap libcgi-pm-perl libdbd-pg-perl

## How to install
- Clone this repo where you want (example on linux: /opt/www)
- cd INSTALLATION_PATH/ansible/group_vars
- cp all.template all
- Edit all the self-explanatory variables in ansible file "all" (path must be the path where you installed wapi, example on linux: /opt/www)
- cd ..
- sudo ansible-playbook install.yml
- cd to nginx etc directory (on linux it is usually /etc/nginx)
- cd sites-available
- sudo ln -s INSTALLATION_PATH/etc/YOUR_PROJECT_NAME.nginx.conf
- cd ../sites-enabled
- sudo ln -s ../YOUR_PROJECT_NAME.nginx.conf
- sudo service nginx restart
- In browser check YOUR_SITE/admin, login: root, password: root, change in soon after your first login.
