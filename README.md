# nginx-ember-fastboot-stack-snippets

Snippets for setting up an Nginx Ember Fastboot stack.

First clone the repository:

```
git clone git@github.com:janwerkhoven/nginx-ember-fastboot-stack-generator.git ~
```

Then run the install script:

```
cd ~/nginx-ember-fastboot-stack-generator
eval "bash generate.sh foo.bar.com 8000 v8.12.0"
```

Warning: This install is quite opinionated and expects you to have a specific setup:

This install assumes:

1.  You are using a remote Ubuntu server.
2.  You are SSH-ed into your server.
3.  Your user has `sudo` privileges.
4.  You have a second user named `deploy` who does not have `sudo` privileges.
5.  Your user and `deploy` belong to the same group, also named `deploy`.
6.  The `deploy` user has the authorisation to pull from your git repo.
7.  Your server has `nvm` installed.
8.  Your server has `git` installed.
9.  Your server has `nginx` installed.
10. Your server has `certbot` installed.
