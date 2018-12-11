#!/bin/bash

set -e

echo "-----"
echo ""
echo "Setting variables..."

domain=$1
port=$2
nvm=$3
pwd=`pwd`
templates="$pwd/templates"
root="/var/www/$domain"

cat <<EOF
  ├─ \$domain = $domain
  ├─ \$port = $port
  ├─ \$nvm = $nvm
  ├─ \$pwd = $pwd
  ├─ \$templates = $templates
  └─ \$root = $root

Setting up project directories...
  ├─ mkdir -p $root/current
  ├─ mkdir -p $root/releases
  ├─ mkdir -p $root/fastboot
  └─ mkdir -p $root/repo
EOF

mkdir -p $root/current
mkdir -p $root/releases
mkdir -p $root/fastboot
mkdir -p $root/repo

cat <<EOF

Setting up Git hooks...
  ├─ cd $root/repo
  ├─ git init --bare
  └─ cp $templates/git-post-receive-hook ./hooks/

EOF

cd $root/repo
git init --bare
cp $templates/git-post-receive-hook ./hooks/

cat <<EOF

Setting up Fastboot...
  ├─ cd $root/fastboot
  ├─ echo "$nvm" >> .nvmrc
  ├─ cp $templates/package.json $root/fastboot/
  ├─ cp $templates/server.js $root/fastboot/
  └─ yarn install

EOF

cd $root/fastboot
echo "$nvm" >> .nvmrc
cp $templates/package.json $root/fastboot/
cp $templates/server.js $root/fastboot/
yarn install

cat <<EOF

Setting up Nginx server block...
  ├─ sed -e "s/interflux.io/$domain/g" -e "s/8001/$port/g" $templates/nginx-server-block > /etc/nginx/sites-available/$domain
  └─ ln -svf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

EOF

sed -e "s/interflux.io/$domain/g" -e "s/8001/$port/g" $templates/nginx-server-block > /etc/nginx/sites-available/$domain
ln -svf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

cat <<EOF

Generating systemd service...
  ├─ sed -e "s/interflux.io/$domain/g" -e "s/v8.12.0/$nvm/g" $templates/systemd-fastboot-service > $root/fastboot/$domain.fastboot.service
  └─ ln -svf $root/fastboot/$domain.fastboot.service /etc/systemd/system/

EOF

sudo sed -e "s/interflux.io/$domain/g" -e "s/v8.12.0/$nvm/g" $templates/systemd-fastboot-service > $root/fastboot/$domain.fastboot.service
sudo ln -svf $root/fastboot/$domain.fastboot.service /etc/systemd/system/

cat <<EOF

Done generating!

-----

To complete the setup:
1. Push production up from your local or CI (git push server production).
2. Make sure git hook triggered and completed.
3. sudo nginx -t
4. sudo systemctl restart nginx
5. Start the fastboot service
sudo ln -svf $root/fastboot/$domain.fastboot.service /etc/systemd/system/
sudo systemctl restart $domain.fastboot.service
sudo systemctl enable $domain.fastboot.service
sudo systemctl daemon-reload
6. Open https://$domain in a browser

-----
EOF
