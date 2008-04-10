###############################################################################
# Write a clean ~/.bash_profile file. This will overwrite the one that already
# exists, so make a backup in case there's something important in the original.
cp ~/.bash_profile ~/.bash_profile.old
cat > ~/.bash_profile << "EOF"
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs
EOF
###############################################################################
# Write a clean ~/.bashrc file and extend the PATH variable to include the
# paths of the applications we're about to build. As with ~/.bash_profile,
# back up the ~/.bashrc file. If you're wondering why the PATH is defined in
# ~/.bashrc and not ~/.bash_profile, it's because ~/.bashrc alone is loaded
# when running automated tasks (when a terminal is not running). This becomes
# important when autostart.cgi scripts are run by apache or with capistrano
# tasks. Put all variable definitions in the ~/.bashrc file.
cp ~/.bashrc ~/.bashrc.old
cat > ~/.bashrc << "EOF"
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific aliases and functions

PATH=$HOME/apps/bin:$HOME/apps/sbin:$HOME/apps/lib/ruby/gems/1.8/bin:$PATH
EOF
###############################################################################
# Write a clean ~/.bash_logout file and backout the original. This isn't all
# that important, but it keeps everyone on the same page.
cp ~/.bash_logout ~/.bash_logout.old
cat > ~/.bash_logout << "EOF"
# ~/.bash_logout

clear
EOF
###############################################################################
# Execute ~/.bash_profile to update the environment.
. ~/.bash_profile
###############################################################################
# The root of your private application environment will be ~/apps. You could
# make it your home directory itself, but I prefer it separate and
# compartmentalized so that it conforms to the File System Hierarchy Standard
# as much as possible. The home directory contains nonstandard directories
# like logs and webapps as well as hidden files and directories that are better
# off separate. That way, if you aren't happy with your private application
# environment, you could simply remove the apps directory and start over fresh.
mkdir ~/apps
chmod 755 ~/apps
# Next create the src directory. This is where sources will be downloaded and
# compiled.
mkdir ~/apps/src
###############################################################################
# 1. ruby 1.8.6 patchlevel 114
# The good thing about having your own ruby install is that you can have the
# most up to date version with security holes patched. You could also have
# custom options enabled when the configure script is run. I leave the custom
# options out here. Those are up to you, but it's fine as is.
cd ~/apps/src
wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p114.tar.gz
tar xzvf ruby-1.8.6-p114.tar.gz
cd ruby-1.8.6-p114
./configure --prefix=$HOME/apps
make
make install
make install-doc
###############################################################################
# 2. rubygems 1.0.1
# Rubygems is the must have companion to ruby. By installing and using it in
# your private application environment, you have total control over gems. You
# can install, update, and uninstall whatever gems you want without having to
# resort to freezing gems in your rails applications.
cd ~/apps/src
wget http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz
tar xzvf rubygems-1.0.1.tgz
cd rubygems-1.0.1
$HOME/apps/bin/ruby setup.rb
###############################################################################
# 3. Install key gems
# The gems you install are up to you, but these are what I install right off
# the bat. Everybody's probably going to be installing rails. Merb is another
# ruby-based framework that everybody should take a look at. Most of the
# shortcomings of rails are solved by merb. Mongrel is the ubiquitous web
# server written in ruby and mongrel_cluster manages multiple mongrel_rails
# instances. Thin is a web server that uses mongrel's http parsing code and
# improves on mongrel. It's faster than mongrel, has built in support for
# clustering, and with eventmachine >= 0.11.0 supports unix socket listeners,
# which is reason number one why I switched from mongrel to thin. Capistrano
# is for running remote tasks and automated deployment, termios is the ruby
# implementation of the termios the password masker, ferret provides full text
# search, acts_as_ferret serves as a mechanism to use ferret in rails
# applications, god is a watchdog to manage processes, sqlite3-ruby is the
# ruby api for the sqlite3 dbms, mysql provides native bindings to the mysql
# dbms, and typo is a rails blogging application. Typo isn't necessary but
# I've included it because I use it. The most important gems are rails, thin,
# capistrano, mysql, and termios. If you use another dbms, get the gem for it.
# Eventmachine is installed from a specific source because as of this writing,
# the one that comes from rubyforge is 0.10.0. That version does not provide
# unix socket listeners for thin.
gem install rails merb mongrel mongrel_cluster thin capistrano \
            termios ferret acts_as_ferret god sqlite3-ruby mysql typo
gem install eventmachine --source http://code.macournoyer.com
###############################################################################
# 4. git 1.5.4.5
# Git is the future of scm. It is way better than subversion. In just a couple
# of days it has proven itself invaluable to me. It provides git-svn which
# allows you the work with subversion repositories. Subversion is installed
# already by WebFaction. Unfortunately, git is not. So install it in your
# private application environment. Making the documentation requires many
# dependencies and it's more trouble than it's worth. Man pages and html
# documentation are available at http://www.kernel.org/pub/software/scm/git/ as
# tarballs if you want them.
cd ~/apps/src
wget http://kernel.org/pub/software/scm/git/git-1.5.4.5.tar.gz
tar xzvf git-1.5.4.5.tar.gz
cd git-1.5.4.5
./configure --prefix=$HOME/apps
make all
make install
###############################################################################
# 5. nginx 0.5.35
# For good reason, the most popular frontend webserver for rails applications
# is nginx. It's fast at serving static pages created by rails page caching,
# easy to configure, a great reverse proxy, and requires very little memory.
# It's upstream directive supports backend servers listening on unix
# socket connections in addition to TCP ports. When built with the
# nginx-upstream-fair module, nginx can provide load balancing far more
# effective than the round robin technique that comes standard. Enabling fair
# load balancing is as easy as adding "fair;" to the block of upstream servers.
# It doesn't have all the bells and whistles of apache, but that's why it's so
# great. Performance is the direct result of nginx's simplicity. Early on, its
# lack of English documentation was nginx's only downside, but because it has
# become an integral part of the "rails stack", support from the rails community
# is now quite substantial.
#
# Here we download the sources for openssl, pcre, zlib, and nginx and git clone
# the nginx-upstream-fair module. Nginx will be compiled with the help of the
# other sources. Three other modules will be built into nginx: http_ssl_module,
# http_flv_module, and http_realip_module. The first provides support for
# https, the second allows for streaming flash videos, and the third allows you
# to configure the real source IP.
cd ~/apps/src
wget http://www.openssl.org/source/openssl-0.9.8g.tar.gz
tar xzvf openssl-0.9.8g.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-7.6.tar.gz
tar xzvf pcre-7.6.tar.gz
wget http://www.zlib.net/zlib-1.2.3.tar.gz
tar xzvf zlib-1.2.3.tar.gz
wget http://sysoev.ru/nginx/nginx-0.5.35.tar.gz
tar xzvf nginx-0.5.35.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
cd nginx-0.5.35
./configure \
--with-pcre=$HOME/apps/src/pcre-7.6 \
--with-zlib=$HOME/apps/src/zlib-1.2.3 \
--with-openssl=$HOME/apps/src/openssl-0.9.8g \
--with-http_realip_module \
--with-http_ssl_module \
--with-http_flv_module \
--add-module=$HOME/apps/src/nginx-upstream-fair \
--prefix=$HOME/apps \
--conf-path=$HOME/apps/etc/nginx/nginx.conf \
--error-log-path=$HOME/apps/var/log/nginx/error.log \
--http-log-path=$HOME/apps/var/log/nginx/access.log \
--pid-path=$HOME/apps/var/run/nginx.pid \
--lock-path=$HOME/apps/var/run/nginx.lock \
--http-client-body-temp-path=$HOME/apps/var/run/nginx/client_body_temp \
--http-proxy-temp-path=$HOME/apps/var/run/nginx/proxy_temp \
--http-fastcgi-temp-path=$HOME/apps/var/run/nginx/fastcgi_temp
make
make install
###############################################################################
# Remove the html directory created by nginx. It's out of place and not
# necessary.
rm -rfd ~/apps/html
# Remove the log directory created by nginx, create a symlink to the
# central log directory, and recreate the nginx directory inside the
# symlinked log directory.
rm -rfd ~/apps/var/log
ln -s $HOME/logs/user $HOME/apps/var/log
mkdir ~/apps/var/log/nginx
# Make the run/nginx directory for the three nginx directories.
mkdir ~/apps/var/run/nginx
# Symlink ~/webapps to ~/apps/var/www, a more standardized location for
# data pertaining to websites.
ln -s $HOME/webapps $HOME/apps/var/www
# Create a tmp directory. This is where unix sockets should be located.
mkdir ~/apps/var/tmp
chmod 777 ~/apps/var/tmp
# Create a directory to store start/stop/restart scripts for daemons. I call it
# rc.d, but it really doesn't matter. The name init.d might be more appropriate
# considering that WebFaction machines use RHEL/CentOS, but I'm partial to
# rc.d. Later we'll use crontab to mimic the system's daemon launching on reboot.
mkdir ~/apps/etc/rc.d
###############################################################################
# Create the nginx start/stop/restart script.
cat > ~/apps/etc/rc.d/nginx << "EOF"
#!/bin/sh
#
# Nginx daemon control script.
# 
# This is an init script for the nginx daemon.
# To use nginx, you must first set up the config file(s).
#
# Written by Cherife Li <cherife@dotimes.com>.
# Source: http://dotimes.com/slackbuilds/nginx/rc.nginx

DAEMON=$HOME/apps/sbin/nginx
CONF=$HOME/apps/etc/nginx/nginx.conf
PID=$HOME/apps/var/run/nginx.pid

nginx_start() {
  # Sanity checks.
  if [ ! -r $CONF ]; then # no config file, exit:
    echo "Please check the nginx config file, exiting..."
    exit
  fi

  if [ -s $PID ]; then
    echo "Nginx is already running?"
    exit
  fi

  echo "Starting Nginx server daemon:"
  if [ -x $DAEMON ]; then
    $DAEMON -c $CONF
  fi
}

nginx_test_conf() {
  echo -e "Checking configuration for correct syntax and\nthen try to open files referred in 
configuration..."
  $DAEMON -t -c $CONF
}

nginx_term() {
  echo "Shutdown Nginx quickly..."
  kill -TERM `cat $PID`
}

nginx_quit() {
  echo "Shutdown Nginx gracefully..."
  kill -QUIT `cat $PID`
}

nginx_reload() {
  echo "Reloading Nginx configuration..."
  kill -HUP `cat $PID`
}

nginx_upgrade() {
  echo -e "Upgrading to the new Nginx binary.\nMake sure the Nginx binary have been replaced 
with new one\nor Nginx server modules were added/removed."
  kill -USR2 `cat $PID`
  sleep 3
  kill -QUIT `cat $PID.oldbin`
}

nginx_restart() {
  nginx_quit
  sleep 5
  nginx_start
}

case "$1" in
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
  echo "usage $0 test|start|term|quit(stop)|reload|restart|upgrade"
esac
EOF
chmod 755 ~/apps/etc/rc.d/nginx
###############################################################################
# We'll get into nginx configuration after building...
# 6. monit 4.10.1
# Monit is a watchdog that manages processes. It makes sure that processes are
# running and that those processes are behaving.
cd ~/apps/src
wget http://www.tildeslash.com/monit/dist/monit-4.10.1.tar.gz
tar xzvf monit-4.10.1.tar.gz
cd monit-4.10.1
./configure --prefix=$HOME/apps
# It's not likely with WebFaction's machines but should configure fail, try:
#./configure --prefix=/usr/local --without-ssl
# I can't get monit to configure correctly with ssl under Debian, but as stated
# above, WebFaction uses RHEL on its older machines and CentOS on its
# newer ones.
make
make install
###############################################################################
# Now let's create the nginx.conf file. It's based on the one created by Ezra
# Zygmuntowicz. Note that the user directive is not enabled because nginx will
# not be run as root.
# Note also the EOF and not "EOF". With the quotations missing from the limit
# string (single or double), you can substitute parameters into the block of
# text. To express $ literally, it must be escaped with a \. See the log format
# definition.
cat > ~/apps/etc/nginx/nginx.conf << EOF
# user and group to run as
#user $USER $USER;

# number of nginx workers
worker_processes  6;

# location of nginx pid file
pid $HOME/apps/var/run/nginx.pid;

events {
  # 1024 worker connections is a good default value
  worker_connections 1024;
}

http {
  # pull in mime types
  include $HOME/apps/etc/nginx/mime.types;

  # set the default mime type
  default_type application/octet-stream;

  # define the 'main' log format
  log_format main '\$remote_addr - \$remote_user [\$time_local] '
                  '"\$request" \$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';

  # location of server access log file
  access_log $HOME/apps/var/log/nginx/nginx_access.log main;

  # location of server error log file
  error_log  $HOME/apps/var/log/nginx/nginx_error.log  debug;

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
    server unix:$HOME/apps/var/tmp/thin.0.sock;
    server unix:$HOME/apps/var/tmp/thin.1.sock;
  }
	
  # load vhost configuration files
  include $HOME/apps/etc/nginx/vhosts/*.conf;
}
EOF
# Now make the vhost directory and certs directory
mkdir ~/apps/etc/nginx/vhosts
mkdir ~/apps/etc/nginx/certs
# We're not going to generate certs here because it requires human interaction.
# Now create some example vhost conf files. You'll need to change the listen
# directive, the server_name directive, and replace appname with the name of
# your app.
cat > ~/apps/etc/nginx/vhosts/appname.conf << EOF
server {
  # port to listen on (can also be IP:PORT)
  listen 9000;

  # domain(s) this vhost serves requests for
  server_name example.com www.example.com;

  # vhost specific access log
  access_log $HOME/apps/var/log/nginx/appname.access.log main;

  # doc root
  root $HOME/apps/var/www/appname/public;

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
    root $HOME/apps/var/www/appname/public;
  }
}
EOF
# Now create an https vhost example file. You need to create SSL certificates
# and modify the file. It's named https.conf.example because we don't want to
# load it when we start nginx.
cat > ~/apps/etc/nginx/vhosts/https.conf.example << EOF
server {
  # port to listen on (can also be IP:PORT)
  listen 443;

  # see http://rubyjudo.com/2006/11/2/nginx-ssl-rails
  ssl on;
  ssl_certificate $HOME/apps/etc/nginx/certs/server.crt;
  ssl_certificate_key $HOME/apps/etc/nginx/certs/server.key;

  # vhost specific access log
  access_log $HOME/apps/var/log/nginx/https.access.log main;

  # doc root
  root $HOME/apps/var/www/appname/public;

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
    root $HOME/apps/var/www/appname/public;
  }
}
EOF
###############################################################################
# Now for the monit start/stop/restart script
# From http://quaddro.net/rcscripts/rc.monit
cat > ~/apps/etc/rc.d/monit << "EOF"
#!/bin/sh
# Start/stop/restart monit
# Important: monit must be set to be a daemon in /etc/monitrc
#
# You will probably want to start this towards the end.
#
MONIT=$HOME/apps/etc/rc.d/monit

monit_start() { 
  $MONIT
}
monit_stop() {
  $MONIT quit
}
monit_restart() {
  monit_stop
  sleep 1
  monit_start
}
monit_reload() {
  $MONIT reload
}
case "$1" in
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
  echo "usage $0 start|stop|restart|reload"
esac
EOF
chmod 755 ~/apps/etc/rc.d/monit
###############################################################################
# Create the main monit configuration file. This comes from Ezra Z.
# It needs to be modified.
cat > ~/apps/etc/monitrc << EOF
set daemon 30 
set logfile syslog facility log_daemon 
set mailserver smtp.example.com 
set mail-format {from:monit@example.com} 
set alert sysadmin@example.com only on { timeout, nonexist } 
set httpd port 9111 
  allow localhost 
include $HOME/apps/etc/monit/* 
EOF
# Make the directory that holds the individual configuration files for monit.
mkdir ~/apps/etc/monit
# Create an example monit configuration file. This one was provided by the thin
# web server project. It's located in the examples directory of the thin gem.
# This file needs editing as well.
cat > ~/apps/etc/monit/blog.monitrc << "EOF"
check process blog1
  with pidfile /u/apps/blog/shared/pids/thin.1.pid
  start program = "/usr/local/bin/ruby /usr/local/bin/thin start -d -e production -S /u/apps/blog/shared/pids/thin.1.sock -P tmp/pids/thin.1.pid -c /u/apps/blog/current"
  stop program  = "/usr/local/bin/ruby /usr/local/bin/thin stop -P /u/apps/blog/shared/pids/thin.1.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket /u/apps/blog/shared/pids/thin.1.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group blog

check process blog2
  with pidfile /u/apps/blog/shared/pids/thin.2.pid
  start program = "/usr/local/bin/ruby /usr/local/bin/thin start -d -e production -S /u/apps/blog/shared/pids/thin.2.sock -P tmp/pids/thin.2.pid -c /u/apps/blog/current"
  stop program  = "/usr/local/bin/ruby /usr/local/bin/thin stop -P /u/apps/blog/shared/pids/thin.2.pid"
  if totalmem > 90.0 MB for 5 cycles then restart
  if failed unixsocket /u/apps/blog/shared/pids/thin.2.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group blog
EOF
###############################################################################
# Now create the main daemon startup script to be run by cron on reboot
cat > ~/apps/etc/rc.user << EOF
#!/bin/bash
# User-level master startup script

$HOME/apps/etc/rc.d/nginx start
$HOME/apps/etc/rc.d/monit start
EOF
chmod 755 ~/apps/etc/rc.user
###############################################################################
# You must add the following line to your crontab file (execute crontab -e):
# @reboot $HOME/apps/etc/rc.user
# You have to generate the ssl cert for nginx https yourself.
# chmod -R g-w . # Revokes write access to group