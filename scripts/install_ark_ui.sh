#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh
echo "Installing ARK-UI"

# Remove old ark-ui
service_uninstall pilot-portal
service_uninstall ark-ui-backend

# clean up old nginx
sudo rm /etc/nginx/sites-enabled/ark-ui &>/dev/null
sudo rm /etc/nginx/sites-available/ark-ui &>/dev/null
sudo rm -rf /var/www/ark-ui &>/dev/null

pushd .
cd $PROJECT_ROOT/submodules/ark-ui
./install.sh
popd

NGINX_CONFIG_FILE_PATH="/etc/nginx/sites-available/ark-ui"
DEPLOY_PATH="$XDG_DATA_HOME/ark-ui"

# Copy nginx config
sudo cp "$COMMON_DIR/ark-ui.nginx" $NGINX_CONFIG_FILE_PATH

# Modify the Nginx config to set the correct root path based on the user
sudo sed -i "s|^\([[:space:]]*root\) .*;|\1 $DEPLOY_PATH/html;|" $NGINX_CONFIG_FILE_PATH

# Copy frontend and backend files to deployment path
mkdir -p $DEPLOY_PATH/html
mkdir -p $DEPLOY_PATH/api
cp -r $PROJECT_ROOT/submodules/ark-ui/ark-ui/dist/* $DEPLOY_PATH/html/
cp -r $PROJECT_ROOT/submodules/ark-ui/backend/* $DEPLOY_PATH/api/

if [ ! -L /etc/nginx/sites-enabled/ark-ui ]; then
  sudo ln -s $NGINX_CONFIG_FILE_PATH /etc/nginx/sites-enabled/ark-ui
fi

# Remove default configuration
sudo rm /etc/nginx/sites-enabled/default &>/dev/null

# add nginx user to $USER group
sudo usermod -aG $USER www-data

# To check that it can run
stat $DEPLOY_PATH

# Test the configuration and restart nginx
sudo nginx -t
sudo systemctl restart nginx

service_add_manifest ark-ui-backend

service_install ark-ui-backend

echo "Finished $(basename $BASH_SOURCE)"
