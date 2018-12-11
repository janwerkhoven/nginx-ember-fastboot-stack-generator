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
  ├─ rm -rf $root/
  ├─ mkdir -p $root/current
  ├─ mkdir -p $root/releases
  ├─ mkdir -p $root/fastboot
  └─ mkdir -p $root/repo
EOF

rm -rf $root/
mkdir -p $root/current
mkdir -p $root/releases
mkdir -p $root/fastboot
mkdir -p $root/repo

cat <<EOF

Setting up Git hooks...
  ├─ cd $root/repo
  ├─ git init --bare
  ├─ cp $templates/git-post-receive-hook ./hooks/post-receive
  └─ chmod +x hooks/post-receive

EOF

cd $root/repo
git init --bare
cp $templates/git-post-receive-hook ./hooks/post-receive
chmod +x hooks/post-receive

cat <<EOF

Setting up Fastboot...
  ├─ cd $root/fastboot
  ├─ sed -e "s/foo.com/$domain/g" -e "s/8001/$port/g" $templates/server.js > $root/fastboot/
  ├─ cp $templates/package.json $root/fastboot/
  ├─ echo "$nvm" >> .nvmrc
  └─ yarn install

EOF

cd $root/fastboot
sed -e "s/foo.com/$domain/g" -e "s/8001/$port/g" $templates/server.js > $root/fastboot/server.js
cp $templates/package.json $root/fastboot/
echo "$nvm" >> .nvmrc
yarn install

cat <<EOF

Generating systemd service...
  ├─ sed -e "s/foo.com/$domain/g" -e "s/v8.12.0/$nvm/g" $templates/systemd-fastboot-service > $root/fastboot/$domain.fastboot.service
  └─ ln -svf $root/fastboot/$domain.fastboot.service /etc/systemd/system/

  Action required:
  1. Enter your sudo password.

EOF

sudo sed -e "s/foo.com/$domain/g" -e "s/v8.12.0/$nvm/g" $templates/systemd-fastboot-service > $root/fastboot/$domain.fastboot.service
sudo ln -svf $root/fastboot/$domain.fastboot.service /etc/systemd/system/

cat <<EOF

Setting up temporary Nginx server block...
  ├─ sed "s/foo.com/$domain/g" $templates/nginx-server-block-before-ssl > /etc/nginx/sites-available/$domain
  ├─ ln -svf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
  ├─ sudo cp $templates/best_practices.conf /etc/nginx/snippets
  └─ sudo cp $templates/security_headers.conf /etc/nginx/snippets

EOF

sed "s/foo.com/$domain/g" $templates/nginx-server-block-before-ssl > /etc/nginx/sites-available/$domain
ln -svf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo cp $templates/best_practices.conf /etc/nginx/snippets
sudo cp $templates/security_headers.conf /etc/nginx/snippets

cat <<EOF

Creating SSL certificate...
  └─ sudo certbot --nginx

Action required:
1. Choose $domain.
2. Choose "Attempt to reinstall" (if certificate already exists).
3. Choose "No redirect".

EOF

sudo certbot --nginx

cat <<EOF

Setting up final Nginx server block...
  └─ sed -e "s/foo.com/$domain/g" -e "s/8001/$port/g" $templates/nginx-server-block-after-ssl > /etc/nginx/sites-available/$domain

EOF

sed -e "s/foo.com/$domain/g" -e "s/8001/$port/g" $templates/nginx-server-block-after-ssl > /etc/nginx/sites-available/$domain

cat <<EOF

Action required:

Before we can continue you need to push production from your local to this remote server.

On your local:

cd Code/$domain
git checkout production
git remote remove server
git remote add server ssh://$USER@sgp1.nabu.io/var/www/$domain/repo
git push server production

EOF

read -p 'Did you push production? (y/n): ' didpush
echo "$didpush"
if ! [ "$didpush" == "y" ] ; then
  echo "Install failed. Please start again."
  exit 1
fi

read -p 'Was the last output message "Successfully deployed!"? (y/n): ' sawsuccess
echo "$sawsuccess"
if ! [ "$sawsuccess" == "y" ] ; then
  echo "Install failed. Please start again."
  exit 1
fi

cat <<EOF

Start the Fastboot service...
  ├─ sudo systemctl enable $domain.fastboot.service
  └─ sudo systemctl restart $domain.fastboot.service

EOF

sudo systemctl enable $domain.fastboot.service
sudo systemctl restart $domain.fastboot.service

cat <<EOF

Restart Nginx, only if tests pass...
  ├─ sudo nginx -t
  └─ sudo systemctl restart nginx

EOF

sudo nginx -t
sudo systemctl restart nginx

cat <<EOF

Done!

Open https://$domain

-----
EOF
