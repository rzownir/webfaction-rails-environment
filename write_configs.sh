#!/bin/bash

#------------------------------------------------------------------------------
# Create a directory to store rc scripts for daemons.

mkdir $PREFIX/etc/rc.d

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Create the vhosts directory

mkdir $PREFIX/etc/nginx/vhosts

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Make the directory that holds the individual configuration files for monit.

mkdir $PREFIX/etc/monit

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# PHP
# To avoid time zone warnings

cat > $PREFIX/etc/php.ini << EOF
[date]
date.timezone = "America/New_York"
EOF

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------

# Monit file for memcached
cat > $PREFIX/etc/monit/memcached.monitrc << EOF
check process memcached
	with pidfile $PREFIX/var/run/memcached.pid
	start program "$PREFIX/bin/memcached -d -m 10 -s $PREFIX/var/tmp/memcached.sock -P $PREFIX/var/run/memcached.pid"
	stop program "$PREFIX/etc/rc.d/memcached-stop"
	if totalmem > 25.0 MB for 5 cycles then restart
	if failed unixsocket $PREFIX/var/tmp/memcached.sock then restart
	if cpu usage > 95% for 3 cycles then restart
	if 5 restarts within 5 cycles then timeout
	group memcached
EOF

# This script is the only way to stop memcached it and remove the pid file.
# I had problems with this in the monitrc file.
cat > $PREFIX/etc/rc.d/memcached-stop << EOF
#!/bin/sh

/usr/bin/killall -u $USER memcached
/bin/rm $PREFIX/var/run/memcached.pid
EOF

chmod 755 $PREFIX/etc/rc.d/memcached-stop

# Monit file for php-cgi
cat > $PREFIX/etc/monit/php-cgi.monitrc << EOF
check process php-cgi
  with pidfile $PREFIX/var/run/fastcgi-php.pid
  start program "$PREFIX/bin/spawn-fcgi -s $PREFIX/var/tmp/fastcgi.sock -P $PREFIX/var/run/fastcgi-php.pid -d $PREFIX/etc -- $PREFIX/bin/php-cgi"
  stop program "$PREFIX/etc/rc.d/php-cgi-stop"
  if totalmem > 50.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/fastcgi.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group php-cgi
EOF

# This script is the only way to stop php-cgi and remove the pid file.
# I had problems with this in the monitrc file.
cat > $PREFIX/etc/rc.d/php-cgi-stop << EOF
#!/bin/sh

/bin/kill `/bin/cat $PREFIX/var/run/fastcgi-php.pid`
/bin/rm $PREFIX/var/run/fastcgi-php.pid
EOF

chmod 755 $PREFIX/etc/rc.d/php-cgi-stop

# Monit file for couchdb (Replace port with your couchdb port)
cat > $PREFIX/etc/monit/couchdb.monitrc << EOF
check process couchdb
	with pidfile $PREFIX/var/run/couchdb/couchdb.pid
	start program "$PREFIX/etc/rc.d/couchdb-start"
	stop program "$PREFIX/bin/couchdb -d"
	if totalmem > 50.0 MB for 5 cycles then restart
	if failed port 5984 then restart
	if failed url http://localhost:5984/ and content == '"couchdb"' then restart
	if cpu usage > 95% for 3 cycles then restart
	if 5 restarts within 5 cycles then timeout
	group couchdb
EOF

cat > $PREFIX/etc/rc.d/couchdb-start << EOF
#!/bin/sh

export HOME=$HOME # Absolutely necessary for monit to start couchdb.
\$HOME/apps/bin/couchdb -b -o /dev/null -e /dev/null
EOF

chmod 755 $PREFIX/etc/rc.d/couchdb-start
