#!/bin/bash

# WebFaction Application Stack Build Script
# (c) 2008-2014 - Ronald M. Zownir

#------------------------------------------------------------------------------
# Edit these variables as instructed in the README.
export PREFIX=$HOME/apps
export APP_NAME=myrailsapp
export APP_PORT=4000
export MONIT_PORT=4002
export RUBY_SVN=false
export INSTALL_PHP=false
export INSTALL_COUCHDB=false

# My server is a Xeon E5620 (32-bit mode). Safe CFLAGS:
#CHOST="i686-pc-linux-gnu"
#CFLAGS="-march=prescott -O2 -pipe -fomit-frame-pointer"
#CXXFLAGS="${CFLAGS}"

# No need to use -pipe; doesn't affect code, reduces compile time at the
# expense of greater memory usage during compile.

# To find out what processor your server has, so you can set -march correctly,
# cat /proc/cpuinfo

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Write a clean $HOME/.bash_logout file after backing up the original.

mv $HOME/.bash_logout $HOME/.bash_logout.old

cat > $HOME/.bash_logout << EOF
# ~/.bash_logout

clear
EOF

#------------------------------------------------------------------------------
# Execute $HOME/.bash_profile to update the environment with the changes made.
# Then create the private application environment directory and ensure that it
# has permissions of 755. Afterward, create the directory where sources will be
# downloaded and compiled.

. $HOME/.bash_profile
mkdir -p $PREFIX
chmod 755 $PREFIX
chmod 750 $HOME # In case $PREFIX is $HOME!
mkdir $PREFIX/src

# Specify place for passenger module to compile.
# /tmp won't do (permission denied error because of execbit)
mkdir -p $PREFIX/var/tmp
chmod 755 $PREFIX/var/tmp
export TMPDIR=$PREFIX/var/tmp

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# gnuplot
# Not necessary, but its great to have and I use it

#getunpack http://hivelocity.dl.sourceforge.net/project/gnuplot/gnuplot/4.6.6/gnuplot-4.6.6.tar.gz
#buildinstall gnuplot-4.6.6

#------------------------------------------------------------------------------
# Git (master branch from github.com)
# Git is a great source code management system. Git will be used to retrieve
# the third party nginx-upstream-fair module for nginx.

cd $PREFIX/src
wget https://github.com/git/git/archive/master.zip -O git-master.zip
unzip git-master.zip
cd git-master
make configure
./configure --prefix=$PREFIX
make all
make install

#------------------------------------------------------------------------------
# SQLite3
# The latest sqlite3-ruby gem requires a version of SQLite3 that may be newer
# than what is on your system. Here's how to install your own up-to-date copy.

getunpack http://www.sqlite.org/2014/sqlite-autoconf-3080704.tar.gz
buildinstall sqlite-autoconf-3080704

#------------------------------------------------------------------------------
# openssl
# For ruby openssl

getunpack https://www.openssl.org/source/openssl-1.0.1j.tar.gz
cd $PREFIX/src/openssl-1.0.1j
./config --prefix=$PREFIX
make
make install

#------------------------------------------------------------------------------
# libffi
# For ruby fiddle (optional)

getunpack ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
buildinstall libffi-3.2.1

#------------------------------------------------------------------------------
# libyaml
# For ruby psych

getunpack http://pyyaml.org/download/libyaml/yaml-0.1.5.tar.gz
buildinstall yaml-0.1.5

#------------------------------------------------------------------------------
# gdbm
# For ruby gdbm

getunpack ftp://ftp.gnu.org/gnu/gdbm/gdbm-1.11.tar.gz
buildinstall gdbm-1.11

#------------------------------------------------------------------------------
# memcached

getunpack http://iweb.dl.sourceforge.net/project/levent/libevent/libevent-2.0/libevent-2.0.21-stable.tar.gz
buildinstall libevent-2.0.21-stable

getunpack http://www.memcached.org/files/memcached-1.4.21.tar.gz
buildinstall memcached-1.4.21

#------------------------------------------------------------------------------
# ruby

if [ $RUBY_SVN == true ]; then
	# ruby requires a newer autoconf than on my system
	getunpack http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
	buildinstall autoconf-2.69
	
	cd $PREFIX/src
	svn export http://svn.ruby-lang.org/repos/ruby/branches/ruby_2_2/
	cd ruby_2_2
	$PREFIX/bin/autoconf # For some reason, I have to specify path
	./configure --prefix=$PREFIX --with-opt-dir=$PREFIX --with-openssl-dir=$PREFIX --with-gdbm-dir=$PREFIX --with-yaml-dir=$PREFIX --with-libffi-dir=$PREFIX --disable-install-rdoc
	make
	make install
else
	getunpack http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.0.tar.gz
	buildinstall ruby-2.2.0 --with-opt-dir=$PREFIX --with-openssl-dir=$PREFIX --with-gdbm-dir=$PREFIX --with-yaml-dir=$PREFIX --with-libffi-dir=$PREFIX --disable-install-rdoc
fi

$PREFIX/bin/gem update --system # Update RubyGems installed with ruby
$PREFIX/bin/gem update --no-ri --no-rdoc # Update preinstalled gems

# Install some gems
gem install rack rails thin unicorn passenger capistrano --no-rdoc --no-ri
gem install sqlite3 --no-ri --no-rdoc -- --with-sqlite3-dir=$PREFIX
gem install mysql --no-rdoc --no-ri -- --with-mysql-config=/usr/bin/mysql_config
gem install pg --no-rdoc --no-ri
#gem install psych --no-ri --no-rdoc -- --with-opt-dir=$PREFIX # In case psych doesn't install with ruby
gem install memcache-client --no-rdoc --no-ri # All ruby memcached client
gem install memcached --no-rdoc --no-ri # Fast client with lots of C, but no drop-in support for rails

#------------------------------------------------------------------------------
if [ $INSTALL_PHP == true ]; then
  # PHP
  getunpack http://www.php.net/distributions/php-5.6.4.tar.gz
  buildinstall php-5.6.4 --with-mysql --with-zlib --with-gettext --with-gdbm
  
  # spawn-fcgi
  getunpack http://www.lighttpd.net/download/spawn-fcgi-1.6.4.tar.gz
  buildinstall spawn-fcgi-1.6.4
fi

#------------------------------------------------------------------------------
# Nginx
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

# Note: If upgrading Passenger, and you installed curl along with CouchDB, execute
# the following to prevent PassengerWatchdog from failing to start with nginx
# export LD_RUN_PATH=$PREFIX/lib

# Removed "--with-http_ssl_module \" because frontend webserver is the one that handles https

getunpack ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.36.tar.gz
getunpack http://zlib.net/zlib-1.2.8.tar.gz
getunpack http://nginx.org/download/nginx-1.7.9.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
buildinstall nginx-1.7.9 \
--with-pcre=$PREFIX/src/pcre-8.36 \
--with-zlib=$PREFIX/src/zlib-1.2.8 \
--with-http_realip_module \
--with-http_gzip_static_module \
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

#------------------------------------------------------------------------------
# Remove the html directory created by nginx. It's out of place and was only
# meant to complement the example nginx.conf file that will be replaced soon.

rm -rf $PREFIX/html

#------------------------------------------------------------------------------
# Remove the log directory created by nginx, create a symlink to the central
# user log directory, and recreate the nginx directory inside the symlinked
# log directory.

rm -rf $PREFIX/var/log
ln -s $HOME/logs/user $PREFIX/var/log
mkdir $PREFIX/var/log/nginx

#------------------------------------------------------------------------------
# Create the necessary directory structure for client_body_temp, proxy_temp,
# fastcgi_temp, uwsgi_temp, and scgi_temp directories. Nginx will create those
# directories for us when it runs.

mkdir -p $PREFIX/var/spool/nginx

#------------------------------------------------------------------------------
# Symlink $PREFIX/var/www to $HOME/webapps. $PREFIX/var/www is a more correct
# point of reference to your web applications from a hierarchal point of view.
# The motivation behind this is purely a semantic one.

ln -s $HOME/webapps $PREFIX/var/www

#------------------------------------------------------------------------------
# Create a tmp directory in var. This is where sockets go. Use unix sockets
# where you can instead of ports. They provide lower latency and eliminate
# unnecessary exposure.

# (Already done above for compiling passenger nginx module)

#mkdir $PREFIX/var/tmp
#chmod 777 $PREFIX/var/tmp

#------------------------------------------------------------------------------
# If upgrading nginx...

#nginx -s stop
#sleep 3
#rm $PREFIX/sbin/nginx.old
#nginx

# !!! >>> IMPORTANT <<< !!!
# Edit nginx.conf to include correct paths to ruby and passenger
# Then do nginx -s reload

#------------------------------------------------------------------------------
# Monit
# A watchdog that manages processes and ensures they are running properly

getunpack http://mmonit.com/monit/dist/monit-5.11.tar.gz
buildinstall monit-5.11

#------------------------------------------------------------------------------
if [ $INSTALL_COUCHDB == true ]; then
  # Erlang
  getunpack http://www.erlang.org/download/otp_src_17.4.tar.gz
  buildinstall otp_src_17.4 #--enable-darwin-64bit # Mac OS X >=10.6

  # CouchDB (requires Erlang)
  getunpack http://curl.haxx.se/download/curl-7.39.0.tar.gz
  buildinstall curl-7.39.0

  getunpack http://download.icu-project.org/files/icu4c/54.1/icu4c-54_1-src.tgz
  # cd icu/source && ./runConfigureICU MacOSX --prefix=$PREFIX --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
  buildinstall icu/source

  # Mozilla SpiderMonkey (version 1.8.5, which plays nice with the CouchDB 1.6.1 build)
  getunpack http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
  buildinstall js-1.8.5/js/src

  # Make sure couchdb is linked to the libraries it depends on.
  # I used to have "export LD_LIBRARY_PATH=$PREFIX/lib", but this is hackish.
  # And you would have to either run it before couchdb or put it in .bashrc,
  # which is really bad idea. Google "LD_LIBRARY_PATH bad". It caused problems
  # for me with other programs, which is why I needed to find a better solution.

  # Note to self:
  # This doesn't seem to help on Mac OS X, though. The best solution is to add
  # "export DYLD_LIBRARY_PATH=$PREFIX/lib" (expanding $PREFIX) at the beginning of
  # $PREFIX/bin/couchdb, which is actually just a shell script.

  export LD_RUN_PATH=$PREFIX/lib # Works on WebFaction!

  getunpack http://mirror.cc.columbia.edu/pub/software/apache/couchdb/source/1.6.1/apache-couchdb-1.6.1.tar.gz
  buildinstall apache-couchdb-1.6.1 --with-erlang=$PREFIX/lib/erlang/usr/include --with-js-lib=$PREFIX/lib --with-js-include=$PREFIX/include/js
fi

#------------------------------------------------------------------------------
# Write the configuration files

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/write_configs.sh"

#------------------------------------------------------------------------------
# Start up

monit
monit start all
