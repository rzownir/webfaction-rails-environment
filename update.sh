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
# Monit 5.5

getunpack http://mmonit.com/monit/dist/monit-5.5.tar.gz
buildinstall monit-5.5

###############################################################################
# Git 1.8.2.1
# Git is a great source code management system. Git will be used to retrieve
# the third party nginx-upstream-fair module for nginx.

getunpack http://git-core.googlecode.com/files/git-1.8.2.1.tar.gz
cd git-1.8.2.1
./configure --prefix=$PREFIX
make all
make install

cd $PREFIX/share/man/
wget http://git-core.googlecode.com/files/git-manpages-1.8.2.1.tar.gz
tar xzvf git-manpages-1.8.2.1.tar.gz
rm git-manpages-1.8.2.1.tar.gz

###############################################################################
# SQLite3 3.7.16.2
# The latest sqlite3-ruby gem requires a version of SQLite3 that may be newer
# than what is on your system. Here's how to install your own up-to-date copy.

getunpack http://www.sqlite.org/2013/sqlite-autoconf-3071602.tar.gz
buildinstall sqlite-autoconf-3071602

###############################################################################
# Install RVM and Ruby

curl -L https://get.rvm.io | bash -s stable --ruby

. ~/.bash_profile

gem install rack rails thin unicorn passenger capistrano --no-rdoc --no-ri
gem install sqlite3 --no-ri --no-rdoc -- --with-sqlite3-dir=$PREFIX
gem install mysql --no-rdoc --no-ri -- --with-mysql-config=/usr/bin/mysql_config

###############################################################################
# Nginx 1.2.8

export PASSENGER_ROOT=`passenger-config --root`

# Specify place for passenger module to compile.
# /tmp won't do (permission denied error because of execbit)
export TMPDIR=$PREFIX/var/tmp

export LD_RUN_PATH=$PREFIX/lib

getunpack ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.32.tar.gz
getunpack http://zlib.net/zlib-1.2.7.tar.gz
getunpack http://www.openssl.org/source/openssl-1.0.1e.tar.gz
getunpack http://nginx.org/download/nginx-1.2.8.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
buildinstall nginx-1.2.8 \
--with-pcre=$PREFIX/src/pcre-8.32 \
--with-zlib=$PREFIX/src/zlib-1.2.7 \
--with-openssl=$PREFIX/src/openssl-1.0.1e \
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

################################################################################
# Quit and start nginx and remove old nginx

nginx -s stop
sleep 3
rm $PREFIX/sbin/nginx.old
nginx

# !!! >>> IMPORTANT <<< !!!
# Edit nginx.conf to include correct paths to ruby and passenger
# Then do nginx -s reload

###############################################################################
# Remove the html directory created by nginx. It's out of place and was only
# meant to complement the example nginx.conf file that will be replaced soon.

rm -rf $PREFIX/html

###############################################################################
# Memcached

getunpack https://github.com/downloads/libevent/libevent/libevent-2.0.19-stable.tar.gz
buildinstall libevent-2.0.19-stable

getunpack http://memcached.googlecode.com/files/memcached-1.4.13.tar.gz
buildinstall memcached-1.4.13

# All ruby memcached client
gem install memcache-client --no-rdoc --no-ri

# Fast client with lots of C, but does not have drop-in support for rails
gem install memcached --no-rdoc --no-ri

###############################################################################
# PHP

getunpack http://www.php.net/distributions/php-5.4.4.tar.gz
buildinstall php-5.4.4 --with-mysql --with-zlib --with-gettext --with-gdbm

###############################################################################
# spawn-fcgi

getunpack http://www.lighttpd.net/download/spawn-fcgi-1.6.3.tar.gz
buildinstall spawn-fcgi-1.6.3
