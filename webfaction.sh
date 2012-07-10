#!/bin/bash

# WebFaction Application Stack Build Script
# (c) 2008-2012 - Ronald M. Zownir

###############################################################################
# Edit these variables as instructed in the README.
export PREFIX=$HOME/apps
export APP_NAME=myrailsapp
export APP_PORT=4000
export MONIT_PORT=4002
export RUBYSVN=false

# My server is a Xeon E5620 (32-bit mode). Safe CFLAGS:
#CHOST="i686-pc-linux-gnu"
#CFLAGS="-march=prescott -O2 -pipe -fomit-frame-pointer"
#CXXFLAGS="${CFLAGS}"

# No need to use -pipe; doesn't affect code, reduces compile time at the
# expense of greater memory usage during compile.

# To find out what processor your server has, so you can set -march correctly,
# cat /proc/cpuinfo

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
# of the private application environment binaries. PATH is defined in
# $HOME/.bashrc and not $HOME/.bash_profile, it's because only $HOME/.bashrc is
# loaded when executing automated/remote commands not running in an interactive
# terminal.

mv $HOME/.bashrc $HOME/.bashrc.old

cat > $HOME/.bashrc << EOF
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific aliases and functions
PREFIX=$PREFIX
export PATH=\$PREFIX/bin:\$PREFIX/sbin:\$PATH
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
# Function to download and unarchive .tar.gz files

function getunpack {
	cd $PREFIX/src
	wget $1
	tar xzvf `basename $1`
}

# Build and install from source directory with configure arguments
function buildinstall {
	cd $PREFIX/src/$1
	shift # Shift $1 out of parameters array
	./configure --prefix=$PREFIX $@ # $@ contains all (existing) parameters
	make
	make install
}

###############################################################################
# Git 1.7.11.1
# Git is a great source code management system. Git will be used to retrieve
# the third party nginx-upstream-fair module for nginx.

getunpack http://git-core.googlecode.com/files/git-1.7.11.1.tar.gz
cd git-1.7.11.1
./configure --prefix=$PREFIX
make all
make install

cd $PREFIX/share/man/
wget http://git-core.googlecode.com/files/git-manpages-1.7.11.1.tar.gz
tar xzvf git-manpages-1.7.11.1.tar.gz
rm git-manpages-1.7.11.1.tar.gz

###############################################################################
# SQLite3 3.7.13
# The latest sqlite3-ruby gem requires a version of SQLite3 that may be newer
# than what is on your system. Here's how to install your own up-to-date copy.

getunpack http://www.sqlite.org/sqlite-autoconf-3071300.tar.gz
buildinstall sqlite-autoconf-3071300

###############################################################################
# libyaml 0.1.4
# For ruby 1.9.3 psych

getunpack http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz
buildinstall yaml-0.1.4

###############################################################################
# Install either Ruby 1.9.3-p194 or latest from 1.9.3 subversion branch

if [ $RUBYSVN == true ]
then #-------------------------------------------------------------------------
	cd $PREFIX/src
	svn export http://svn.ruby-lang.org/repos/ruby/branches/ruby_1_9_3/
	cd ruby_1_9_3
	autoconf
	./configure --prefix=$PREFIX --with-opt-dir=$PREFIX
	make
	make install
else #-------------------------------------------------------------------------
	getunpack http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
	buildinstall ruby-1.9.3-p194 --with-opt-dir=$PREFIX
fi #---------------------------------------------------------------------------

# RubyGems installs with Ruby 1.9.3
$PREFIX/bin/gem update --system # Ensure RubyGems is up to date
$PREFIX/bin/gem update --no-ri --no-rdoc # Ensure preinstalled gems are up to date

# Install some gems...
gem install rack rails thin unicorn passenger capistrano --no-rdoc --no-ri
gem install sqlite3 --no-ri --no-rdoc -- --with-sqlite3-dir=$PREFIX
gem install mysql --no-rdoc --no-ri -- --with-mysql-config=/usr/bin/mysql_config
#gem install psych --no-ri --no-rdoc -- --with-opt-dir=$PREFIX # In case psych doesn't install with ruby

###############################################################################
# Nginx 1.2.2
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
# other sources. Four other modules will be built into nginx: http_realip_module,
# http_gzip_static_module, http_ssl_module, and http_flv_module. The first allows
# you to establish the real source IP if nginx isn't the frontend server. The
# second allows you to serve pre-compressed .gz files. The third provides support
# for https. The fourth enables the streaming of flash videos. You don't have to
# install the three aforementioned modules, but it's a good idea to. Just make
# sure to include the nginx-upstream-fair module.

export PASSENGER_ROOT=`passenger-config --root`

# Specify place for passenger module to compile.
# /tmp won't do (permission denied error because of execbit)
mkdir -p $PREFIX/var/tmp
chmod 777 $PREFIX/var/tmp
export TMPDIR=$PREFIX/var/tmp

# Note:
# If upgrading Passenger, and you installed curl along with CouchDB, run:
# export LD_RUN_PATH=$PREFIX/lib
# right here to prevent PassengerWatchdog from failing to start with nginx.

getunpack ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.31.tar.gz
getunpack http://zlib.net/zlib-1.2.7.tar.gz
getunpack http://www.openssl.org/source/openssl-1.0.1c.tar.gz
getunpack http://nginx.org/download/nginx-1.2.2.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
buildinstall nginx-1.2.2 \
--with-pcre=$PREFIX/src/pcre-8.31 \
--with-zlib=$PREFIX/src/zlib-1.2.7 \
--with-openssl=$PREFIX/src/openssl-1.0.1c \
--with-http_realip_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--with-http_flv_module \
--add-module=$PREFIX/src/nginx-upstream-fair \
--add-module=$PASSENGER_ROOT/ext/nginx \
--conf-path=$PREFIX/etc/nginx/nginx.conf \
--error-log-path=$PREFIX/var/log/nginx/error.log \
--http-log-path=$PREFIX/var/log/nginx/access.log \
--pid-path=$PREFIX/var/run/nginx.pid \
--lock-path=$PREFIX/var/run/nginx.lock \
--http-client-body-temp-path=$PREFIX/var/spool/nginx/client_body_temp \
--http-proxy-temp-path=$PREFIX/var/spool/nginx/proxy_temp \
--http-fastcgi-temp-path=$PREFIX/var/spool/nginx/fastcgi_temp \
--http-uwsgi-temp-path=$PREFIX/var/spool/nginx/uwsgi_temp \
--http-scgi-temp-path=$PREFIX/var/spool/nginx/scgi_temp

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
# fastcgi_temp, uwsgi_temp, and scgi_temp directories. Nginx will create those
# directories for us when it runs.

mkdir -p $PREFIX/var/spool/nginx

###############################################################################
# Symlink $PREFIX/var/www to $HOME/webapps. $PREFIX/var/www is a more correct
# point of reference to your web applications from a hierarchal point of view.
# The motivation behind this is purely a semantic one.

ln -s $HOME/webapps $PREFIX/var/www

###############################################################################
# Create a tmp directory in var. This is where sockets go. Use unix sockets
# where you can instead of ports. They provide lower latency and eliminate
# unnecessary exposure.

# (Already done above for compiling passenger nginx module)

#mkdir $PREFIX/var/tmp
#chmod 777 $PREFIX/var/tmp

###############################################################################
# Create a directory to store rc scripts for daemons.

mkdir $PREFIX/etc/rc.d

###############################################################################
# Create the nginx rc script. I improved the second if structure in nginx_start
# so that an orphan nginx pid file does not cause a problem.

cat > $PREFIX/etc/rc.d/nginx << EOF
#!/bin/sh
#
# Nginx daemon control script.
# 
# This is an rc script for the nginx daemon.
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
# Create the nginx.conf file, based on the one by Ezra Zygmuntowicz. The user
# directive is commented out because the nginx master process is not run by
# root. Therefore, the worker processes are run by nobody, the default user.

cat > $PREFIX/etc/nginx/nginx.conf << EOF
# user and group to run as
#user $USER $USER;

worker_processes  4;

pid $PREFIX/var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  passenger_root $PASSENGER_ROOT;
  passenger_ruby $PREFIX/bin/ruby;
  passenger_max_pool_size 4; # max total instances (default is 6)
  passenger_max_instances_per_app 2;
  passenger_friendly_error_pages off; # don't expose traces to site visitors

  set_real_ip_from 192.168.1.0/24; # [public] server IP (change this to your IP)
  set_real_ip_from 127.0.0.1;
  real_ip_header X-Real-IP;

  include $PREFIX/etc/nginx/mime.types;
  default_type application/octet-stream;

  # might need to substitute $http_x_forwarded_for for $remote_addr if $remote_addr
  # turns out to be 127.0.0.1
  log_format main '\$remote_addr - \$remote_user [\$time_local] '
                  '"\$request" \$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';
  access_log $PREFIX/var/log/nginx/access.log main;
  error_log  $PREFIX/var/log/nginx/error.log  debug;

  sendfile on; # turn off on Mac OS X

  tcp_nopush on;
  tcp_nodelay off;

  gzip on;
	gzip_static on;
  gzip_http_version 1.0;
  gzip_buffers 16 8k;
  gzip_comp_level 5;
  gzip_proxied any;
  gzip_types text/plain text/css application/x-javascript text/xml application/rss+xml;

  # reverse proxy clusters
  upstream thin {
    fair; # requires nginx-upstream-fair module
    server unix:$PREFIX/var/tmp/thin.0.sock;
    server unix:$PREFIX/var/tmp/thin.1.sock;
    #server 127.0.0.1:5000;
    #server 127.0.0.1:5001;
    #server 127.0.0.1:5002;
  }

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
# directive is practically irrelevant for https vhosts. For http vhosts however,
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
# Permanently move address from www.example.com to example.com
# server {
#   listen 4321;
#   server_name www.example.com;
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
  server_name .example.com; # Change this or comment it out
	access_log $PREFIX/var/log/nginx/${APP_NAME}_access.log main;
  root $PREFIX/var/www/$APP_NAME/public;
  passenger_enabled on;
}
EOF

###############################################################################
# Create a sample vhost file for using a thin cluster instead of passenger.
# Because the extension is .example it will not be loaded when nginx starts.

cat > $PREFIX/etc/nginx/vhosts/$APP_NAME-thin.conf.example << EOF
server {
  listen $APP_PORT; # Can also be IP:PORT
  server_name .example.com;
  access_log $PREFIX/var/log/nginx/${APP_NAME}_access.log main;
  root $PREFIX/var/www/$APP_NAME/public;

  client_max_body_size 20M; # Max size for file uploads

  location / {
    try_files /system/maintenance.html \$uri \$uri/index.html \$uri.html @backend;
  }

  location @backend {
    proxy_set_header  X-Real-IP       \$remote_addr;
    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header  Host            \$http_host;
    proxy_redirect false;
    proxy_max_temp_file_size 0;
    proxy_pass http://thin;
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
# modify the conf according to your circumstances.

# Since your private nginx is not the frontmost server, both http and https
# requests will land on a single nginx http vhost. Therefore, you may need to
# create a proxy header in the nginx conf file that differentiates between http
# and https requests. You will have to see for yourself, since I haven't
# worked this out myself.

cat > $PREFIX/etc/nginx/vhosts/https.conf.example << EOF
server {
  listen 443;
  access_log $PREFIX/var/log/nginx/https_access.log main;
  root $PREFIX/var/www/$APP_NAME/public;
  passenger_enabled on;

  # See http://rubyjudo.com/2006/11/2/nginx-ssl-rails
  ssl on;
  ssl_certificate $PREFIX/etc/nginx/certs/server.crt;
  ssl_certificate_key $PREFIX/etc/nginx/certs/server.key;
}
EOF

###############################################################################
# Create a sample https vhost file for use with a thin cluster.

cat > $PREFIX/etc/nginx/vhosts/https-thin.conf.example << EOF
server {
  listen 443; # Probably going to use IP:443
  access_log $PREFIX/var/log/nginx/https_access.log main;
  root $PREFIX/var/www/$APP_NAME/public;

  client_max_body_size 20M; # Max size for file uploads

  # See http://rubyjudo.com/2006/11/2/nginx-ssl-rails
  ssl on;
  ssl_certificate $PREFIX/etc/nginx/certs/server.crt;
  ssl_certificate_key $PREFIX/etc/nginx/certs/server.key;

  location / {
    try_files /system/maintenance.html \$uri \$uri/index.html \$uri.html @backend;
  }

  location @backend {
    proxy_set_header X-FORWARDED_PROTO https;
    proxy_set_header X-Real-IP         \$remote_addr;
    proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header Host              \$http_host;
    proxy_redirect false;
    proxy_max_temp_file_size 0;
    proxy_pass http://thin;
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root $PREFIX/var/www/$APP_NAME/public;
  }
}
EOF

###############################################################################
# Monit 5.4
# Monit is a watchdog that manages processes. It makes sure that processes are
# running and that they behave.

getunpack http://mmonit.com/monit/dist/monit-5.4.tar.gz
buildinstall monit-5.4

# Note to self:
# If configure fails, try:
# ./configure --prefix=$PREFIX --without-ssl
# I can't get monit to configure successfully with ssl on Debian, but
# WebFaction uses RHEL on its older machines and CentOS on its newer ones.
# Things should go without a hitch on WebFaction's machines.

###############################################################################
# Create the monitrc file. Edit and uncomment lines as necessary.

cat > $PREFIX/etc/monitrc << EOF
set daemon 60 # 30, 60, or 120 second intervals are good
set logfile $PREFIX/var/log/monit.log
set httpd port $MONIT_PORT #and use address MY-IP-ADDRESS
	allow localhost
	#allow MY-IP-ADDRESS
	#allow username:password # basic auth
#set mailserver smtp.gmail.com port 587 username "MYUSERNAME@gmail.com" password "MYPASSWORD" using tlsv1 with timeout 30 seconds
#set mail-format {from:monit@example.com}
#set alert sysadmin@example.com #only on { timeout, nonexist } # Default email to send alerts to
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
  if totalmem > 15.0 MB for 5 cycles then restart
  if failed port $APP_PORT then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group nginx
EOF

###############################################################################
# Create a sample monit configuration file for the thin servers. This is based
# on the one that comes with the thin gem. It's located in the thin gem's
# examples directory.

cat > $PREFIX/etc/monit/$APP_NAME.monitrc.example << EOF
check process ${APP_NAME}0
  with pidfile $PREFIX/var/run/thin.0.pid
  start program = "$PREFIX/bin/ruby $PREFIX/bin/thin start -d -c $PREFIX/var/www/$APP_NAME -e production -s 2 -S $PREFIX/var/tmp/thin.sock -P $PREFIX/var/run/thin.pid -o 0"
  stop program  = "$PREFIX/bin/ruby $PREFIX/bin/thin stop -P $PREFIX/var/run/thin.0.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/thin.0.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group $APP_NAME

check process ${APP_NAME}1
  with pidfile $PREFIX/var/run/thin.1.pid
  start program = "$PREFIX/bin/ruby $PREFIX/bin/thin start -d -c $PREFIX/var/www/$APP_NAME -e production -s 2 -S $PREFIX/var/tmp/thin.sock -P $PREFIX/var/run/thin.pid -o 1"
  stop program  = "$PREFIX/bin/ruby $PREFIX/bin/thin stop -P $PREFIX/var/run/thin.1.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/thin.1.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group $APP_NAME
EOF

###############################################################################
# Create the boot script. The script removes pid files from the canonical
# location $PREFIX/var/run. Orphaned pid files will prevent applications such
# as thin from starting. The script will then start monit which in turn will
# start up all monitored applications. "monit start all" isn't strictly
# necessary, but if you execute "monit stop all" or "monit stop APP_NAME", monit
# remembers this and won't start them automatically on reboot just by calling
# "monit". Such daemons need to be reactivated using "monit start all" or "monit
# start APP_NAME".

# Be careful running the boot script arbitrarily; you don't want to delete the
# pid files of running processes! If you do, don't panic. Execute "killall -u $USER".
# Your ssh session will be killed along with all of your applications. Login
# again and execute "$PREFIX/etc/rc.d/boot" to "reboot" your stack.

cat > $PREFIX/etc/rc.d/boot << EOF
#!/bin/sh

. \$HOME/.bash_profile
find \$PREFIX/var/run/ -type f -name *.pid -print0 | xargs -0 rm
monit
monit start all
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
/usr/sbin/logrotate -s $PREFIX/var/lib/logrotate.status $PREFIX/etc/logrotate.conf
EOF
cat $PREFIX/var/tmp/oldcrontab >> $PREFIX/var/tmp/newcrontab
crontab $PREFIX/var/tmp/newcrontab
rm $PREFIX/var/tmp/oldcrontab $PREFIX/var/tmp/newcrontab

mkdir -p $PREFIX/var/lib
touch $PREFIX/var/lib/logrotate.status

cat > $PREFIX/etc/logrotate.conf << EOF
$HOME/logs/user/nginx/*.log {
  monthly
  rotate 6
  compress
  postrotate
    $PREFIX/etc/rc.d/nginx restart
  endscript
}
EOF

# Note to self:
# crontab isn't working on my ArchLinux machine. The crontab file works
# perfectly fine on WebFaction, however.

###############################################################################
# Start up

monit
monit start all

# If you want to use thin instead of passenger:
# 1. Move nginx vhost...
# mv $PREFIX/etc/nginx/vhosts/$APP_NAME.conf $PREFIX/etc/nginx/vhosts/$APP_NAME-passenger.conf.example
# mv $PREFIX/etc/nginx/vhosts/$APP_NAME-thin.conf.example $PREFIX/etc/nginx/vhosts/$APP_NAME.conf
# 2. Move monitrc file...
# mv $PREFIX/etc/monit/$APP_NAME.monitrc.example $PREFIX/etc/monit/$APP_NAME.monitrc
# 3. Reinitialize monit and restart all monitored applications...
# monit reload
# monit restart all
# 4. To save memory, prevent passenger processes from starting up with nginx.
#    You have to manually edit $PREFIX/etc/nginx/nginx.conf. Comment out the
#    passenger directives: passenger_root (most importantly), passenger_ruby,
#    passenger_max_pool_size, and any others. Then restart nginx.
# 5. Also, make sure that the upstream thin directive is uncommented in the
#    nginx.conf file. I did not comment it out because it doesn't do any harm.
