# Experimenting with the encap package management scheme.

# The variable name ENCAP_TARGET is meaningful to epkg and mkencap. It tells
# them where to find and install packages. Put this in the bashrc.

export ENCAP_TARGET=$HOME/usr
export PATH=$ENCAP_TARGET/bin:$ENCAP_TARGET/sbin:$PATH
export GEM_HOME=$ENCAP_TARGET/encap/gems-1.9/lib/ruby/gems/1.9.1

mkdir -p $ENCAP_TARGET/src/encap_pkgs

###############################################################################
# Function to download and unarchive .tar.gz files

function getunpack {
	cd $ENCAP_TARGET/src
	wget $1
	tar xzvf `basename $1`
}

# Build and install from source directory with configure arguments
function buildinstall {
	cd $ENCAP_TARGET/src/$1
	shift # Shift $1 out of parameters array
	./configure $@ # $@ contains all (existing) parameters
	make
	make install
}

function encapify {
	epkg $1
	cd $ENCAP_TARGET/src/encap_pkgs
	mkencap $1-$2
}

###############################################################################
# Encap
 
getunpack ftp://ftp.encap.org/pub/encap/epkg/epkg-2.3.9.tar.gz
buildinstall epkg-2.3.9 --prefix=$ENCAP_TARGET

###############################################################################
# Git

getunpack http://git-core.googlecode.com/files/git-1.7.8.tar.gz
cd git-1.7.8
./configure --prefix=$ENCAP_TARGET/encap/git-1.7.8
make all
make install

cd $ENCAP_TARGET/encap/git-1.7.8/share/man
wget http://git-core.googlecode.com/files/git-manpages-1.7.8.tar.gz
tar xzvf git-manpages-1.7.8.tar.gz
rm git-manpages-1.7.8.tar.gz

encapify git 1.7.8

###############################################################################
# SQLite3

getunpack http://www.sqlite.org/sqlite-autoconf-3070900.tar.gz
buildinstall sqlite-autoconf-3070900 --prefix=$ENCAP_TARGET/encap/sqlite-3.7.9
encapify sqlite 3.7.9

###############################################################################
# Ruby

getunpack http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz
buildinstall ruby-1.9.3-p0 --prefix=$ENCAP_TARGET/encap/ruby-1.9.3_p0 --disable-install-doc # Using _ instead of - to comform with encap specs
encapify ruby 1.9.3_p0

# A seemless way to isolate the gems from the ruby installation (?)
mkdir $ENCAP_TARGET/encap/gem-repository-1.9
cd $ENCAP_TARGET/encap/gem-repository-1.9
mkdir -p lib/ruby/gems/1.9.1/bin
ln -s lib/ruby/gems/1.9.1/bin bin

export GEM_HOME=$ENCAP_TARGET/encap/gems-1.9/lib/ruby/gems/1.9.1

gem install rake rdoc minitest rails thin unicorn passenger capistrano --no-ri --no-rdoc
gem install sqlite3-ruby -- --with-sqlite3-dir=$ENCAP_TARGET --no-ri --no-rdoc
gem install mysql -- --with-mysql-config=/usr/bin/mysql_config --no-ri --no-rdoc
#gem install termios --no-ri --no-rdoc # Problem building with ruby 1.9.3

epkg gems -f

###############################################################################
# Nginx

export PASSENGER_ROOT=`passenger-config --root`
cd $PASSENGER_ROOT/ext/nginx
$ENCAP_TARGET/encap/ruby-1.9.3_p0/bin/rake nginx

getunpack http://www.openssl.org/source/openssl-1.0.0e.tar.gz
getunpack ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.20.tar.gz
getunpack http://zlib.net/zlib-1.2.5.tar.gz
getunpack http://nginx.org/download/nginx-1.0.10.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
buildinstall nginx-1.0.10 \
--with-pcre=$ENCAP_TARGET/src/pcre-8.20 \
--with-zlib=$ENCAP_TARGET/src/zlib-1.2.5 \
--with-openssl=$ENCAP_TARGET/src/openssl-1.0.0e \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_realip_module \
--add-module=$ENCAP_TARGET/src/nginx-upstream-fair \
--add-module=$PASSENGER_ROOT/ext/nginx \
--prefix=$ENCAP_TARGET/encap/nginx-1.0.10 \
--conf-path=$ENCAP_TARGET/etc/nginx/nginx.conf \
--error-log-path=$ENCAP_TARGET/var/log/nginx/error.log \
--http-log-path=$ENCAP_TARGET/var/log/nginx/access.log \
--pid-path=$ENCAP_TARGET/var/run/nginx.pid \
--lock-path=$ENCAP_TARGET/var/run/nginx.lock \
--http-client-body-temp-path=$ENCAP_TARGET/var/spool/nginx/client_body_temp \
--http-proxy-temp-path=$ENCAP_TARGET/var/spool/nginx/proxy_temp \
--http-fastcgi-temp-path=$ENCAP_TARGET/var/spool/nginx/fastcgi_temp \
--http-uwsgi-temp-path=$ENCAP_TARGET/var/spool/nginx/uwsgi_temp \
--http-scgi-temp-path=$ENCAP_TARGET/var/spool/nginx/scgi_temp


rm -rf $ENCAP_TARGET/encap/nginx-1.0.10/html
mkdir $ENCAP_TARGET/encap/nginx-1.0.10/etc
mv $ENCAP_TARGET/etc/nginx $ENCAP_TARGET/encap/nginx-1.0.10/etc

# CONF FILES NOT INCLUDED IN PKG AS THEY ARE INSTALLED IN TARGET
# MOVE CONF FILES TO SRC (BECAUSE WANT TARGET AS DEFAULT) THEN MAKE IT SO
# CONF FILES MOVED INTO PLACE ONLY IF THEY DON'T EXIST

# PREINSTALL SCRIPT
# -- ADD RC.D FILE
# POSTINSTALL SCRIPT
# -- create empty dirs
# ENCAPINFO FILE
# -- EXCLUDE ETC
# CHMOD PRE/POSTINSTALL 755

encapify nginx 1.0.10

###############################################################################
# Monit

getunpack http://mmonit.com/monit/dist/monit-5.3.1.tar.gz
buildinstall monit-5.3.1 --prefix=$ENCAP_TARGET/encap/monit-5.3.1
encapify monit 5.3.1

# PREINSTALL SCRIPT
# -- RC.D FILE
# POSTINSTALL SCRIPT
# -- ETC copy if nec
# ENCAPINFO
# -- excl etc

###############################################################################
# PHP

getunpack http://www.php.net/distributions/php-5.3.8.tar.gz
buildinstall php-5.3.8 --prefix=$ENCAP_TARGET/encap/php-5.3.8 --with-mysql --with-zlib --with-gettext --with-gdbm
encapify php 5.3.8

# ENCAPINFO
# -- exclude etc
# PREINSTALL
# -- etc files
# -- create etc/php.ini
# POSTINSTALL
# -- move etc files into place

###############################################################################
# spawn-fcgi

getunpack http://www.lighttpd.net/download/spawn-fcgi-1.6.3.tar.gz
buildinstall spawn-fcgi-1.6.3 --prefix=$ENCAP_TARGET/encap/spawn-fcgi-1.6.3
encapify spawn-fcgi 1.6.3

# ENCAPINFO
# -- exclude etc
# PREINSTALL
# -- rc.d file
# POSTINSTALL
# -- move rc.d file into place

###############################################################################
# Memcached

# libevent
getunpack https://github.com/downloads/libevent/libevent/libevent-2.0.16-stable.tar.gz
buildinstall libevent-2.0.16-stable --prefix=$ENCAP_TARGET/encap/libevent-2.0.16
encapify libevent 2.0.16

# memcached
getunpack http://memcached.googlecode.com/files/memcached-1.4.10.tar.gz
buildinstall memcached-1.4.10 --prefix=$ENCAP_TARGET/encap/memcached-1.4.10 --with-libevent=$ENCAP_TARGET
encapify memcached 1.4.10

# libmemcached
getunpack http://launchpad.net/libmemcached/1.0/1.0.2/+download/libmemcached-1.0.2.tar.gz
export CFLAGS="-march=i686" # Fixes compile problem
buildinstall libmemcached-1.0.2  --prefix=$ENCAP_TARGET/encap/libmemcached-1.0.2
encapify libmemcached 1.0.2

#gem install memcache-client memcached --no-rdoc --no-ri

###############################################################################
# Erlang

getunpack http://www.erlang.org/download/otp_src_R14B04.tar.gz
buildinstall otp_src_R14B04 --prefix=$ENCAP_TARGET/encap/erlang-R14B04 #--enable-darwin-64bit # Mac OS X >=10.6
encapify erlang R14B04

###############################################################################
# CouchDB (requires erlang, icu4c, curl, spidermonkey)

# curl
getunpack http://curl.haxx.se/download/curl-7.23.1.tar.gz
buildinstall curl-7.23.1 --prefix=$ENCAP_TARGET/encap/curl-7.23.1
encapify curl 7.23.1

# icu
getunpack http://download.icu-project.org/files/icu4c/4.8.1.1/icu4c-4_8_1_1-src.tgz
#cd icu/source && ./runConfigureICU MacOSX --prefix=$ENCAP_TARGET/encap/icu4c-4.8.1.1 --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
buildinstall icu/source --prefix=$ENCAP_TARGET/encap/icu4c-4.8.1.1
encapify icu4c 4.8.1.1

# SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz.
# But we'll use the latest standalone version.

getunpack http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
buildinstall js-1.8.5/js/src --prefix=$ENCAP_TARGET/encap/js-1.8.5
encapify js 1.8.5

# couchdb
export LD_RUN_PATH=$ENCAP_TARGET/lib # This is going to be a little tricky with encap

getunpack http://mirror.cc.columbia.edu/pub/software/apache//couchdb/1.1.1/apache-couchdb-1.1.1.tar.gz
buildinstall apache-couchdb-1.1.1 --prefix=$ENCAP_TARGET/encap/couchdb-1.1.1 --with-erlang=$ENCAP_TARGET/lib/erlang/usr/include --with-js-lib=$ENCAP_TARGET/lib --with-js-include=$ENCAP_TARGET/include
encapify couchdb 1.1.1
