#!/bin/bash

set -e

echo '-----'
echo 'Setting variables...'

domain=$1
echo "\$domain = $domain"

port=$2
echo "\$port = $port"

# TODO nvm=`nvm current`
nvm=$3
echo "\$nvm = $nvm"

pwd=`pwd`
echo "\$pwd = $pwd"

templates="$pwd/templates"
echo "\$templates = $templates"

root="/var/www/$domain"
echo "\$root = $root"

echo 'Setting up project directories...'
mkdir -p $root/current
mkdir -p $root/releases
mkdir -p $root/fastboot
mkdir -p $root/repo

echo 'Setting up Git hooks...'
cd $root/repo
git init --bare
cp $templates/git-post-receive-hook ./hooks/

echo 'Setting up Fastboot...'
cd $root/fastboot
echo "$nvm" >> .nvmrc
cp $templates/package.json $root/fastboot/
cp $templates/server.js $root/fastboot/
yarn install

echo 'Generating Nginx server block...'
sed -e "s/interflux.io/$domain/g" -e "s/8001/$port/g" $templates/nginx-server-block > /etc/nginx/sites-available/$domain

echo 'Enabling Nginx server block...'
ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

echo 'Generating systemd service...'
sed -e "s/interflux.io/$domain/g" -e "s/v8.12.0/$nvm/g" $templates/systemd-fastboot-service > /etc/systemd/system/$domain.fastboot.service

echo 'Done generating!'
echo ' '
echo 'To complete the setup:'
echo `1. Push production up from your local or CI (git push server production).`
echo `2. Make sure git hook triggered and completed.`
echo `3. sudo nginx -t`
echo `4. sudo systemctl restart nginx`
echo `5. sudo systemctl restart $domain.fastboot.service`
echo `6. Open https://$domain in a browser`
echo '-----'
