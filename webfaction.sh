#!/bin/bash

# WebFaction Ruby on Rails Stack Builder
# (c) 2008 - Ronald M. Zownir

###############################################################################
# Edit these variables as instructed in the README.
export PREFIX=$HOME/apps
export APP_NAME=typo
export APP_PORT=4000
export MONIT_PORT=4002

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
mkdir $PREFIX/src

###############################################################################
# Ruby 1.8.6 (latest from the 1.8.6 subversion branch)
# The good thing about having your own ruby install is that you can have the
# most up to date version with security holes patched. You could also have
# custom options enabled when the configure script is executed. I leave the
# customization up to you, but it's fine as it is here.

cd $PREFIX/src
svn export http://svn.ruby-lang.org/repos/ruby/branches/ruby_1_8_6/
cd ruby_1_8_6
autoconf
./configure --prefix=$PREFIX
make
make install
#make install-doc # Documentation generation is ridiculously memory hungry!

###############################################################################
# RubyGems 1.3.0
# By installing RubyGems in your private application environment, you have
# total control over the gems you require. You can install, update, and
# uninstall whatever gems you want without having to freeze gems in your rails
# applications.

cd $PREFIX/src
wget http://rubyforge.org/frs/download.php/43985/rubygems-1.3.0.tgz
tar xzvf rubygems-1.3.0.tgz
cd rubygems-1.3.0
$PREFIX/bin/ruby setup.rb --no-rdoc --no-ri

###############################################################################
# Gems
# The following gems (along with their dependencies) will be installed:
# rails - it's probably the reason you care to take a look at this script
# merb - another great ruby web framework
# mongrel, mongrel_cluster - the standard backend web server for rails apps
# thin - mongrel's successor: mongrel's http parser, built in clustering,
#   unix socket listener support
# capistrano - for running remote tasks and automated deployment
# termios - ruby implementation of the termios password masker
# ferret, acts_as_ferret - full text search capability for rails models
# god - watchdog and process manager that can be used instead of monit
# sqlite3-ruby - bindings to the sqlite3 dbms
# mysql - bindings to the mysql dbms
# typo - rails blogging application

gem install rails merb mongrel mongrel_cluster thin capistrano \
            termios ferret acts_as_ferret god sqlite3-ruby mysql \
            --no-rdoc --no-ri

# The typo blog application currently requires rail version 2.0.2
gem install rails -v '= 2.0.2' --no-rdoc --no-ri
gem install typo --no-rdoc --no-ri

###############################################################################
# Git 1.6.0.2
# Git is a great source code management system. Subversion is already installed
# on WebFaction's machines, but git is not. Git will be used to retrieve the
# third party nginx-upstream-fair module for nginx.

cd $PREFIX/src
wget http://kernel.org/pub/software/scm/git/git-1.6.0.2.tar.gz
tar xzvf git-1.6.0.2.tar.gz
cd git-1.6.0.2
./configure --prefix=$PREFIX
make all
make install

cd $PREFIX/share/man/
wget http://kernel.org/pub/software/scm/git/git-manpages-1.6.0.2.tar.gz
tar xzvf git-manpages-1.6.0.2.tar.gz
rm git-manpages-1.6.0.2.tar.gz

###############################################################################
# Nginx 0.6.32
# For good reason, the most popular frontend webserver for rails applications
# is nginx. It's easy to configure, requires very little memory even under
# heavy load, fast at serving static pages created with rails page caching, and
# a capable reverse proxy and load balancer. It's a nice all-in-one solution
# that just works! It's upstream directive supports backend servers listening
# on unix socket connections in addition to TCP ports. When built with the
# nginx-upstream-fair module, nginx can provide load balancing far more
# effective than the round robin technique that comes standard. Enabling fair
# load balancing is as easy as adding "fair;" to the block of upstream servers.
#
# Here we download the sources for openssl, pcre, zlib, and nginx and git clone
# the nginx-upstream-fair module. Nginx will be compiled with the help of the
# other sources. Three other modules will be built into nginx: http_ssl_module,
# http_flv_module, and http_realip_module. The first provides support for
# https, the second enables streaming flash videos, and the third allows you to
# configure the real source IP if nginx isn't the spearhead frontend server.
# You don't have to install the three aforementioned modules, but it's a good
# idea to. Just make sure to include the nginx-upstream-fair module.

cd $PREFIX/src
wget http://www.openssl.org/source/openssl-0.9.8i.tar.gz
tar xzvf openssl-0.9.8i.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-7.8.tar.gz
tar xzvf pcre-7.8.tar.gz
wget http://www.zlib.net/zlib-1.2.3.tar.gz
tar xzvf zlib-1.2.3.tar.gz
wget http://sysoev.ru/nginx/nginx-0.6.32.tar.gz
tar xzvf nginx-0.6.32.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
cd nginx-0.6.32
./configure \
--with-pcre=$PREFIX/src/pcre-7.8 \
--with-zlib=$PREFIX/src/zlib-1.2.3 \
--with-openssl=$PREFIX/src/openssl-0.9.8i \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_realip_module \
--add-module=$PREFIX/src/nginx-upstream-fair \
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
# Create a tmp directory in var. This is where I put the sockets for the thin
# cluster. You might want to locate them in your rails application's
# tmp/sockets directory, but you'll have to modify this script in a few
# locations.

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
# Before writing the configuration for nginx, let's build...
# Monit 4.10.1
# Monit is a watchdog that manages processes. It makes sure that processes are
# running and that they behave.

cd $PREFIX/src
wget http://www.tildeslash.com/monit/dist/monit-4.10.1.tar.gz
tar xzvf monit-4.10.1.tar.gz
cd monit-4.10.1
./configure --prefix=$PREFIX
make
make install

# Note [to self]: If configure fails, try:
# ./configure --prefix=$PREFIX --without-ssl
# I can't get monit to configure successfully with ssl on Debian, but
# WebFaction uses RHEL on its older machines and CentOS on its newer ones.
# Things should go without a hitch on WebFaction's machines; end users ignore.

###############################################################################
# Now let's create the nginx.conf file. It's based on the one created by Ezra
# Zygmuntowicz. The user directive is commented out because the nginx
# master process is not run by root. Therefore the worker processes must run by
# nobody, the default user.

cat > $PREFIX/etc/nginx/nginx.conf << EOF
# user and group to run as
#user $USER $USER;

# number of nginx workers
worker_processes  6;

# location of nginx pid file
pid $PREFIX/var/run/nginx.pid;

events {
  # 1024 worker connections is a good default value
  worker_connections 1024;
}

http {
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

  upstream thin {
    fair;
    server unix:$PREFIX/var/tmp/thin.0.sock;
    server unix:$PREFIX/var/tmp/thin.1.sock;
  }
	
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
#   rewrite ^ http://example.com$uri permanent;
# }
# 
# server {
#   listen 4321;
#   server_name example.com;
#   ...

cat > $PREFIX/etc/nginx/vhosts/$APP_NAME.conf << EOF
server {
  # port to listen on (can also be IP:PORT)
  listen $APP_PORT;

  # domain(s) this vhost serves requests for
  #server_name example.com www.example.com;

  # vhost specific access log
  access_log $PREFIX/var/log/nginx/${APP_NAME}_access.log main;

  # doc root
  root $PREFIX/var/www/$APP_NAME/public;

  # set the max size for file uploads to 20Mb
  client_max_body_size 20M;

  # with capistrano's disable web task, rewrite all requests to maintenance.html
  if (-f \$document_root/system/maintenance.html) {
    rewrite  ^(.*)\$  /system/maintenance.html last;
    break;
  }

  location / {
    # set headers for passing the request to the backend
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_redirect false;
    proxy_max_temp_file_size 0;

    # serve the static file if it exists
    if (-f \$request_filename) { 
      break; 
    }

    # serve static directory index if it exists
    if (-f \$request_filename/index.html) {
      rewrite (.*) \$1/index.html break;
    }

    # necessary rule for rails page caching
    if (-f \$request_filename.html) {
      rewrite (.*) \$1.html break;
    }

    # set necessary headers and pass the request to the upstream cluster
    if (!-f \$request_filename) {
      proxy_pass http://thin;
      break;
    }
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root $PREFIX/var/www/$APP_NAME/public;
  }
}
EOF

###############################################################################
# Create a sample https vhost file. You'll need to create SSL certificates
# (see http://www.akadia.com/services/ssh_test_certificate.html on how) and
# modify the conf according to your circumstances. It's named
# https.conf.example so it won't be loaded when nginx is started. With
# WebFaction, you probably aren't going to be doing https from nginx; it will
# likely be done from Apache, which is the "spearhead" server. Both http and
# https requests will land on a single nginx http vhost. You may need to create
# a proxy header in the nginx conf file that differentiates between http and
# https requests. If somebody could post a comment about how, that'd be great.

cat > $PREFIX/etc/nginx/vhosts/https.conf.example << EOF
server {
  # port to listen on (can also be IP:PORT)
  listen 443;

  # see http://rubyjudo.com/2006/11/2/nginx-ssl-rails
  ssl on;
  ssl_certificate $PREFIX/etc/nginx/certs/server.crt;
  ssl_certificate_key $PREFIX/etc/nginx/certs/server.key;

  # vhost specific access log
  access_log $PREFIX/var/log/nginx/https_access.log main;

  # doc root
  root $PREFIX/var/www/$APP_NAME/public;

  # set the max size for file uploads to 20Mb
  client_max_body_size 20M;

  # with capistrano's disable web task, rewrite all requests to maintenance.html
  if (-f \$document_root/system/maintenance.html) {
    rewrite  ^(.*)\$  /system/maintenance.html last;
    break;
  }

  location / {
    # set headers for passing the request to the backend
    proxy_set_header X-FORWARDED_PROTO https;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_redirect false;
    proxy_max_temp_file_size 0;
    
    # serve the static file if it exists
    if (-f \$request_filename) { 
      break; 
    }

    # serve static directory index if it exists
    if (-f \$request_filename/index.html) {
      rewrite (.*) \$1/index.html break;
    }

    # necessary rule for rails page caching
    if (-f \$request_filename.html) {
      rewrite (.*) \$1.html break;
    }

    # set necessary headers and pass the request to the upstream cluster
    if (!-f \$request_filename) {
      proxy_pass http://thin;
      break;
    }
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root $PREFIX/var/www/$APP_NAME/public;
  }
}
EOF

###############################################################################
# Create the monit rc script (from http://quaddro.net/rcscripts/rc.monit). This
# file is deprecated because it doesn't offer any real advantages. It will
# remain for now, however.

cat > $PREFIX/etc/rc.d/monit << EOF
#!/bin/sh
# Start/stop/restart monit
# Important: monit must be set to be a daemon in $PREFIX/etc/monitrc
#
# You will probably want to start this towards the end.
#
MONIT=$PREFIX/bin/monit

monit_start() { 
  \$MONIT
}
monit_stop() {
  \$MONIT quit
}
monit_restart() {
  monit_stop
  sleep 1
  monit_start
}
monit_reload() {
  \$MONIT reload
}
case "\$1" in
'start')
  monit_start
  ;;
'stop')
  monit_stop
  ;;
'restart')
  monit_restart
  ;;
'reload')
  monit_reload
  ;;
*)
  echo "usage \$0 start|stop|restart|reload"
esac
EOF

chmod 755 $PREFIX/etc/rc.d/monit

###############################################################################
# Create the monitrc file. This comes from Ezra Zygmuntowicz. I've commented
# out all but the essential lines. This works perfectly fine, but it could
# use touch up.

cat > $PREFIX/etc/monitrc << EOF
set daemon 30 
#set logfile syslog facility log_daemon 
#set mailserver smtp.example.com 
#set mail-format {from:monit@example.com} 
#set alert sysadmin@example.com only on { timeout, nonexist } 
set httpd port $MONIT_PORT
  allow localhost 
include $PREFIX/etc/monit/*.monitrc
EOF

chmod 700 $PREFIX/etc/monitrc

###############################################################################
# Make the directory that holds the individual configuration files for monit.

mkdir $PREFIX/etc/monit

###############################################################################
# Create a monit configuration file for nginx. It's wise to have a failed port
# line for each port nginx listens on. Feel free to tweak the numbers as you
# see fit.

cat > $PREFIX/etc/monit/nginx.monitrc << EOF
check process nginx
  with pidfile $PREFIX/var/run/nginx.pid
  start program "$PREFIX/etc/rc.d/nginx start"
  stop program "$PREFIX/etc/rc.d/nginx stop"
  if totalmem > 25.0 MB for 5 cycles then restart
  if failed port $APP_PORT then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group nginx
EOF

###############################################################################
# Create a monit configuration file for the thin servers. This is based on the
# one that comes with the thin gem. It's located in the thin gem's examples
# directory.

cat > $PREFIX/etc/monit/$APP_NAME.monitrc << EOF
check process ${APP_NAME}0
  with pidfile $PREFIX/var/www/$APP_NAME/tmp/pids/thin.0.pid
  start program = "$PREFIX/bin/ruby $PREFIX/bin/thin start -d -c $PREFIX/var/www/$APP_NAME -e production -s 2 -S $PREFIX/var/tmp/thin.sock -P $PREFIX/var/www/$APP_NAME/tmp/pids/thin.pid -o 0"
  stop program  = "$PREFIX/bin/ruby $PREFIX/bin/thin stop -P $PREFIX/var/www/$APP_NAME/tmp/pids/thin.0.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/thin.0.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group $APP_NAME

check process ${APP_NAME}1
  with pidfile $PREFIX/var/www/$APP_NAME/tmp/pids/thin.1.pid
  start program = "$PREFIX/bin/ruby $PREFIX/bin/thin start -d -c $PREFIX/var/www/$APP_NAME -e production -s 2 -S $PREFIX/var/tmp/thin.sock -P $PREFIX/var/www/$APP_NAME/tmp/pids/thin.pid -o 1"
  stop program  = "$PREFIX/bin/ruby $PREFIX/bin/thin stop -P $PREFIX/var/www/$APP_NAME/tmp/pids/thin.1.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/thin.1.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group $APP_NAME
EOF

###############################################################################
# Create the boot script. The script removes pid files from web app locations.
# Thin will not start if it has orphaned pid files. The script will then start
# monit which in turn will start up nginx and the thin servers. Be careful
# running this script arbitrarily; you don't want to delete the pid files of
# running processes!

cat > $PREFIX/etc/rc.d/boot << EOF
. \$HOME/.bash_profile
find \$PREFIX/var/www/ -type f -name *.pid -print0 | xargs -0 rm
monit
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
# Fire up monit, nginx, and the thin servers!

monit