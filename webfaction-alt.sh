#!/bin/bash

# WebFaction Ruby on Rails Stack Builder
# (c) 2008-2009 - Ronald M. Zownir

###############################################################################
# Edit these variables as instructed in the README.
export PREFIX=$HOME/apps
export APP_NAME=blog
export APP_PORT=4000

###############################################################################
# Back up $HOME/.bash_profile and write a clean file. The string limiter
# definition can be quoted with single or double quotes at the beginning to
# prevent parameter substitution. We require parameter substitution here.

mv $HOME/.bash_profile $HOME/.bash_profile.old

cat > $HOME/.bash_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs
EOF

###############################################################################
# Back up $HOME/.bashrc and write a new file. Extend $PATH to include the paths
# of the private application environment binaries. If you're wondering why the
# PATH is defined in $HOME/.bashrc and not $HOME/.bash_profile, it's because
# only $HOME/.bashrc is loaded when executing automated/remote commands not
# running in an interactive terminal.

mv $HOME/.bashrc $HOME/.bashrc.old

cat > $HOME/.bashrc << EOF
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific aliases and functions
PREFIX=$PREFIX
PATH=\$PREFIX/bin:\$PREFIX/sbin:\$PATH
EOF

###############################################################################
# Write a clean $HOME/.bash_logout file after backing up the original.

mv $HOME/.bash_logout $HOME/.bash_logout.old

cat > $HOME/.bash_logout << EOF
# ~/.bash_logout

clear
EOF

###############################################################################
# Execute $HOME/.bash_profile to update the environment with the changes made.
# Then create the private application environment directory and ensure that it
# has permissions of 755. Afterward, create the directory where sources will be
# downloaded and compiled.

. $HOME/.bash_profile
mkdir -p $PREFIX
chmod 755 $PREFIX
chmod 750 $HOME # In case $PREFIX is $HOME!
mkdir $PREFIX/src

###############################################################################
# Ruby Enterprise Edition 1.8.6 - 20090610
# Reduces memory consumption of rails apps by up to 33% when used with Passenger.

cd $PREFIX/src
wget http://rubyforge.org/frs/download.php/58677/ruby-enterprise-1.8.6-20090610.tar.gz
tar xzvf ruby-enterprise-1.8.6-20090610.tar.gz
cd ruby-enterprise-1.8.6-20090610
./installer -a $PREFIX

# Make sure RubyGems is up to date
$PREFIX/bin/gem update --system

# Common gems are installed with Ruby Enterprise Edition include:
# fastthread, mysql, passenger, rack, rails, rake, rubygems-update, sqlite3-ruby

###############################################################################
# Additional Gems
# The following gems (along with their dependencies) will be installed:
# thin - mongrel's successor: mongrel's http parser, built in clustering,
#   unix socket listener support
# capistrano - for running remote tasks and automated deployment
# termios - ruby implementation of the termios password masker

gem install thin capistrano termios --no-rdoc --no-ri

###############################################################################
# Git 1.6.4.2
# Git is a great source code management system. Subversion is already installed
# on WebFaction's machines, but git is not.

cd $PREFIX/src
wget http://kernel.org/pub/software/scm/git/git-1.6.4.2.tar.gz
tar xzvf git-1.6.4.2.tar.gz
cd git-1.6.4.2
./configure --prefix=$PREFIX
make all
make install

cd $PREFIX/share/man/
wget http://kernel.org/pub/software/scm/git/git-manpages-1.6.4.2.tar.gz
tar xzvf git-manpages-1.6.4.2.tar.gz
rm git-manpages-1.6.4.2.tar.gz

###############################################################################
# Nginx 0.7.61
# Here we download the sources for openssl, pcre, zlib, and nginx and git clone
# the nginx-upstream-fair module. Nginx will be compiled with the help of the
# other sources. Four other modules will be built into nginx: http_ssl_module,
# http_flv_module, http_realip_module, and passenger. The first provides support
# for https, the second enables streaming flash videos, the third allows you to
# configure the real source IP if nginx isn't the spearhead frontend server, and
# the last is the module that hooks up to passenger.

export PASSENGER_ROOT=`passenger-config --root`

cd $PREFIX/src
wget http://www.openssl.org/source/openssl-0.9.8k.tar.gz
tar xzvf openssl-0.9.8k.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-7.9.tar.gz
tar xzvf pcre-7.9.tar.gz
wget http://www.zlib.net/zlib-1.2.3.tar.gz
tar xzvf zlib-1.2.3.tar.gz
wget http://sysoev.ru/nginx/nginx-0.7.61.tar.gz
tar xzvf nginx-0.7.61.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
cd nginx-0.7.61
./configure \
--with-pcre=$PREFIX/src/pcre-7.9 \
--with-zlib=$PREFIX/src/zlib-1.2.3 \
--with-openssl=$PREFIX/src/openssl-0.9.8k \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_realip_module \
--add-module=$PREFIX/src/nginx-upstream-fair \
--add-module=$PASSENGER_ROOT/ext/nginx \
--prefix=$PREFIX \
--conf-path=$PREFIX/etc/nginx/nginx.conf \
--error-log-path=$PREFIX/var/log/nginx/error.log \
--http-log-path=$PREFIX/var/log/nginx/access.log \
--pid-path=$PREFIX/var/run/nginx.pid \
--lock-path=$PREFIX/var/run/nginx.lock \
--http-client-body-temp-path=$PREFIX/var/spool/nginx/client_body_temp \
--http-proxy-temp-path=$PREFIX/var/spool/nginx/proxy_temp \
--http-fastcgi-temp-path=$PREFIX/var/spool/nginx/fastcgi_temp
make
make install

###############################################################################
# Remove the html directory created by nginx. It's out of place and was only
# meant to complement the example nginx.conf file that will be replaced soon.

rm -rf $PREFIX/html

###############################################################################
# Remove the log directory created by nginx, create a symlink to the central
# user log directory, and recreate the nginx directory inside the symlinked
# log directory.

rm -rf $PREFIX/var/log
ln -s $HOME/logs/user $PREFIX/var/log
mkdir $PREFIX/var/log/nginx

###############################################################################
# Create the necessary directory structure for client_body_temp, proxy_temp,
# and fastcgi_temp directories. Nginx will create those directories for us when
# it runs.

mkdir -p $PREFIX/var/spool/nginx

###############################################################################
# Symlink $PREFIX/var/www to $HOME/webapps. $PREFIX/var/www is a more correct
# point of reference to your web applications from a hierarchal point of view.
# The motivation behind this is purely a semantic one.

ln -s $HOME/webapps $PREFIX/var/www

###############################################################################
# Create a tmp directory in var. This is where I would put sockets.

mkdir $PREFIX/var/tmp
chmod 777 $PREFIX/var/tmp

###############################################################################
# Create a directory to store rc scripts for daemons.

mkdir $PREFIX/etc/rc.d

###############################################################################
# Create the nginx rc script. I improved the second if structure in nginx_start
# so that an orphan nginx pid file does not pose a problem.

cat > $PREFIX/etc/rc.d/nginx << EOF
#!/bin/sh
#
# Nginx daemon control script.
# 
# This is an init script for the nginx daemon.
# To use nginx, you must first set up the config file(s).
#
# Written by Cherife Li <cherife@dotimes.com>.
# Source: http://dotimes.com/slackbuilds/nginx/rc.nginx

DAEMON=$PREFIX/sbin/nginx
CONF=$PREFIX/etc/nginx/nginx.conf
PID=$PREFIX/var/run/nginx.pid

nginx_start() {
  # Sanity checks.
  if [ ! -r \$CONF ]; then # no config file, exit:
    echo "Please check the nginx config file, exiting..."
    exit
  fi

  if [[ -s \$PID && \`ps -p \\\`cat \$PID\\\` -o comm=\` = "nginx" ]]; then
    echo "Nginx is already running?"
    exit
  fi

  echo "Starting Nginx server daemon:"
  if [ -x \$DAEMON ]; then
    \$DAEMON -c \$CONF
  fi
}

nginx_test_conf() {
  echo -e "Checking configuration for correct syntax and\nthen try to open files referred in configuration..."
  \$DAEMON -t -c \$CONF
}

nginx_term() {
  echo "Shutdown Nginx quickly..."
  kill -TERM \`cat \$PID\`
}

nginx_quit() {
  echo "Shutdown Nginx gracefully..."
  kill -QUIT \`cat \$PID\`
}

nginx_reload() {
  echo "Reloading Nginx configuration..."
  kill -HUP \`cat \$PID\`
}

nginx_upgrade() {
  echo -e "Upgrading to the new Nginx binary.\nMake sure the Nginx binary have been replaced with new one\nor Nginx server modules were added/removed."
  kill -USR2 \`cat \$PID\`
  sleep 3
  kill -QUIT \`cat \$PID.oldbin\`
}

nginx_restart() {
  nginx_quit
  sleep 5
  nginx_start
}

case "\$1" in
'test')
  nginx_test_conf
  ;;
'start')
  nginx_start
  ;;
'term')
  nginx_term
  ;;
'quit'|'stop')
  nginx_quit
  ;;
'reload')
  nginx_reload
  ;;
'restart')
  nginx_restart
  ;;
'upgrade')
  nginx_upgrade
  ;;
*)
  echo "usage \$0 test|start|term|quit(stop)|reload|restart|upgrade"
esac
EOF

chmod 755 $PREFIX/etc/rc.d/nginx

###############################################################################
# Now let's create the nginx.conf file. It's based on the one created by Ezra
# Zygmuntowicz. The user directive is commented out because the nginx
# master process is not run by root. Therefore the worker processes must run by
# nobody, the default user.

cat > $PREFIX/etc/nginx/nginx.conf << EOF
# user and group to run as
#user $USER $USER;

# number of nginx workers
worker_processes  4;

# location of nginx pid file
pid $PREFIX/var/run/nginx.pid;

events {
  # 1024 worker connections is a good default value
  worker_connections 1024;
}

http {
	passenger_root $PASSENGER_ROOT;
	passenger_ruby $PREFIX/bin/ruby;
	passenger_max_pool_size 2; # How many passenger instances can exist (default was 6)
	
  # pull in mime types
  include $PREFIX/etc/nginx/mime.types;

  # set the default mime type
  default_type application/octet-stream;

  # define the 'main' log format
  log_format main '\$remote_addr - \$remote_user [\$time_local] '
                  '"\$request" \$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';

  # location of server access log file
  access_log $PREFIX/var/log/nginx/access.log main;

  # location of server error log file
  error_log  $PREFIX/var/log/nginx/error.log  debug;

  # turn sendfile off on Mac OS X
  sendfile on;

  # good default values
  tcp_nopush on;
  tcp_nodelay off;

  # output commpression saves bandwidth
  gzip on;
  gzip_http_version 1.0;
  gzip_comp_level 2;
  gzip_proxied any;
  gzip_types text/plain text/html text/css application/x-javascript text/xml
             application/xml application/xml+rss text/javascript;
	
	# reverse proxy clusters
  # upstream mongrel {
  #   # fair load balancing requires the nginx-upstream-fair module
  #   fair;
  #   server 127.0.0.1:5000;
  #   server 127.0.0.1:5001;
  #   server 127.0.0.1:5002;
  # }

  # upstream thin {
  #   fair;
  #   server unix:$PREFIX/var/tmp/thin.0.sock;
  #   server unix:$PREFIX/var/tmp/thin.1.sock;
  # }
	
  # load vhost configuration files
  include $PREFIX/etc/nginx/vhosts/*.conf;
}
EOF

###############################################################################
# Create the vhost and certs directories

mkdir $PREFIX/etc/nginx/vhosts
mkdir $PREFIX/etc/nginx/certs

###############################################################################
# Create a vhost conf file based on the information provided at the beginning
# of this script. With http vhosts (as opposed to https vhosts using ssl), you
# would normally assign them each a name using the server_name directive.
# Because ssl certificates validated by a Certificate Authority are pegged
# to an IP address rather than a domain or subdomain, the server_name
# directive is virtually irrelevant for https vhosts. For http vhosts however,
# the directive differentiates vhosts listening on a single port by the domain
# name used to reach the server. The server_name doesn't really matter unless
# you want to make such a distinction. WebFaction uses the Apache equivalent to
# connect your domains and subdomains listening on port 80 (http) or 443
# (https) to the port assigned to your rails application. There's not much of a
# need for the server_name directive on WebFaction because Apache handles the
# most common use case for you behind the scenes. One instance in which
# server_name does come in handy on WebFaction is if you want to rewrite a
# domain from www.example.com to example.com or example.net to example.com.
# This requires that the involved domains/subdomains point to the same app
# (more specifically the same port) as configured on the sites page of the
# WebFaction control panel. Here's how to do that in a vhost conf file:
#
# Permanently moving address from example.net or www.example.net to example.com
# server {
#   listen 4321;
#   server_name example.net www.example.net;
#   rewrite ^ $scheme://example.com$uri permanent;
# }
# 
# server {
#   listen 4321;
#   server_name example.com;
#   ...

cat > $PREFIX/etc/nginx/vhosts/$APP_NAME.conf << EOF
server {
	listen $APP_PORT;
  server_name example.com;
  root $PREFIX/var/www/$APP_NAME/public;
	passenger_enabled on;

	# vhost specific access log
  access_log $PREFIX/var/log/nginx/${APP_NAME}_access.log main;
}
EOF

###############################################################################
# Create a sample https vhost file. You'll need to create SSL certificates
# (see http://www.akadia.com/services/ssh_test_certificate.html on how) and
# modify the conf according to your circumstances. It's named
# https.conf.example so it won't be loaded when nginx is started.

cat > $PREFIX/etc/nginx/vhosts/https.conf.example << EOF
server {
  listen 443;
  root $PREFIX/var/www/$APP_NAME/public;
	passenger_enabled on;

  # vhost specific access log
  access_log $PREFIX/var/log/nginx/https_access.log main;

  # see http://rubyjudo.com/2006/11/2/nginx-ssl-rails
  ssl on;
  ssl_certificate $PREFIX/etc/nginx/certs/server.crt;
  ssl_certificate_key $PREFIX/etc/nginx/certs/server.key;
}
EOF

###############################################################################
# Create the boot script. The script removes pid files from web app locations.
# Be careful running this script arbitrarily; you don't want to delete the pid
# files of running processes!

cat > $PREFIX/etc/rc.d/boot << EOF
. \$HOME/.bash_profile
find \$PREFIX/var/www/ -type f -name *.pid -print0 | xargs -0 rm
\$PREFIX/etc/rc.d/nginx start
EOF

chmod 755 $PREFIX/etc/rc.d/boot

###############################################################################
# To run the boot script when the system reboots, an entry must be made to your
# crontab file. A copy of your crontab is saved first. If the entry to be
# prepended already appears in the original file, it is removed by grep before
# it is saved. The crontab entry is prepended, the new crontab file is enacted,
# and the two temporary files created are removed.

crontab -l | grep -v "@reboot $PREFIX/etc/rc.d/boot" > $PREFIX/var/tmp/oldcrontab
cat > $PREFIX/var/tmp/newcrontab << EOF
@reboot $PREFIX/etc/rc.d/boot
EOF
cat $PREFIX/var/tmp/oldcrontab >> $PREFIX/var/tmp/newcrontab
crontab $PREFIX/var/tmp/newcrontab
rm $PREFIX/var/tmp/oldcrontab $PREFIX/var/tmp/newcrontab

# Note [to self]: crontab isn't working on my ArchLinux machine. The crontab
# file works perfectly fine on WebFaction, so disregard this comment end users.

###############################################################################
$PREFIX/etc/rc.d/boot
