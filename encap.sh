# Experimenting with the encap package management scheme.

# The variable name ENCAP_TARGET is meaningful to epkg and mkencap. It tells
# them where to find and install packages. Put this in the bashrc.

export ENCAP_TARGET=$HOME/usr
export PATH=$ENCAP_TARGET/bin:$ENCAP_TARGET/sbin:$PATH
export GEM_HOME=$ENCAP_TARGET/encap/gems-1.9/lib/ruby/gems/1.9.1

mkdir -p $ENCAP_TARGET/src/encap_pkgs

###############################################################################
# Encap
 
cd $ENCAP_TARGET/src
wget ftp://ftp.encap.org/pub/encap/epkg/epkg-2.3.9.tar.gz
tar xzvf epkg-2.3.9.tar.gz
cd epkg-2.3.9
./configure --prefix=$ENCAP_TARGET
make
make install

###############################################################################
# Git

cd $ENCAP_TARGET/src
wget http://kernel.org/pub/software/scm/git/git-1.7.5.3.tar.gz
tar xzvf git-1.7.5.3.tar.gz
cd git-1.7.5.3
./configure --prefix=$ENCAP_TARGET/encap/git-1.7.5.3
make all
make install

cd $ENCAP_TARGET/encap/git-1.7.5.3/share/man
wget http://kernel.org/pub/software/scm/git/git-manpages-1.7.5.3.tar.gz
tar xzvf git-manpages-1.7.5.3.tar.gz
rm git-manpages-1.7.5.3.tar.gz

epkg git
cd $ENCAP_TARGET/src/encap_pkgs
mkencap git-1.7.5.3

###############################################################################
# SQLite3

cd $ENCAP_TARGET/src
wget http://www.sqlite.org/sqlite-autoconf-3070603.tar.gz
tar xzvf sqlite-autoconf-3070603.tar.gz
cd sqlite-autoconf-3070603
./configure --prefix=$ENCAP_TARGET/encap/sqlite-3.7.6.3
make
make install

epkg sqlite
cd $ENCAP_TARGET/src/encap_pkgs
mkencap sqlite-3.7.6.3

###############################################################################
# Ruby

cd $ENCAP_TARGET/src
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p180.tar.gz
tar xzvf ruby-1.9.2-p180.tar.gz
cd ruby-1.9.2-p180
./configure --prefix=$ENCAP_TARGET/encap/ruby-1.9.2_p180 --disable-install-doc # Using _ instead of - to comform with encap specs
make
make install

epkg ruby
cd $ENCAP_TARGET/src/encap_pkgs
mkencap ruby-1.9.2_p180

# A seemless way to isolate the gems from the ruby installation (?)
mkdir $ENCAP_TARGET/encap/gem-repository-1.9
cd $ENCAP_TARGET/encap/gem-repository-1.9
mkdir -p lib/ruby/gems/1.9.1/bin
ln -s lib/ruby/gems/1.9.1/bin bin

export GEM_HOME=$ENCAP_TARGET/encap/gems-1.9/lib/ruby/gems/1.9.1

gem install rake rdoc minitest rails thin passenger capistrano --no-ri --no-rdoc
gem install passenger --pre --no-ri --no-rdoc
gem install sqlite3-ruby -- --with-sqlite3-dir=$ENCAP_TARGET --no-ri --no-rdoc
gem install mysql -- --with-mysql-config=/usr/bin/mysql_config --no-ri --no-rdoc
#gem install termios --no-ri --no-rdoc # Problem building with ruby 1.9.2

epkg gems -f

###############################################################################
# Nginx

export PASSENGER_ROOT=`passenger-config --root`
cd $PASSENGER_ROOT/ext/nginx
$ENCAP_TARGET/encap/ruby-1.9.2_p0/bin/rake nginx

cd $ENCAP_TARGET/src
wget http://www.openssl.org/source/openssl-1.0.0d.tar.gz
tar xzvf openssl-1.0.0d.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.12.tar.gz
tar xzvf pcre-8.12.tar.gz
wget http://zlib.net/zlib-1.2.5.tar.gz
tar xzvf zlib-1.2.5.tar.gz
wget http://nginx.org/download/nginx-1.0.3.tar.gz
tar xzvf nginx-1.0.3.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
cd nginx-1.0.3
./configure \
--with-pcre=$ENCAP_TARGET/src/pcre-8.12 \
--with-zlib=$ENCAP_TARGET/src/zlib-1.2.5 \
--with-openssl=$ENCAP_TARGET/src/openssl-1.0.0d \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_realip_module \
--add-module=$ENCAP_TARGET/src/nginx-upstream-fair \
--add-module=$PASSENGER_ROOT/ext/nginx \
--prefix=$ENCAP_TARGET/encap/nginx-1.0.3 \
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
make
make install

rm -rf $ENCAP_TARGET/encap/nginx-1.0.3/html
mkdir $ENCAP_TARGET/encap/nginx-1.0.3/etc
mv $ENCAP_TARGET/etc/nginx $ENCAP_TARGET/encap/nginx-1.0.3/etc

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

epkg nginx
cd $ENCAP_TARGET/src/encap_pkgs
mkencap nginx-1.0.3

###############################################################################
# Monit

cd $ENCAP_TARGET/src
wget http://mmonit.com/monit/dist/monit-5.2.5.tar.gz
tar xzvf monit-5.2.5.tar.gz
cd monit-5.2.5
./configure --prefix=$ENCAP_TARGET/encap/monit-5.2.5
make
make install

epkg monit
cd $ENCAP_TARGET/src/encap_pkgs
mkencap monit-5.2.5


# PREINSTALL SCRIPT
# -- RC.D FILE
# POSTINSTALL SCRIPT
# -- ETC copy if nec
# ENCAPINFO
# -- excl etc

###############################################################################
# PHP

cd $ENCAP_TARGET/src
wget http://us.php.net/get/php-5.3.6.tar.gz/from/this/mirror
tar xzvf php-5.3.6.tar.gz
cd php-5.3.6
./configure --prefix=$ENCAP_TARGET/encap/php-5.3.6 --with-mysql --with-zlib --with-gettext --with-gdbm
make
make install

epkg php
cd $ENCAP_TARGET/src/encap_pkgs
mkencap php-5.3.6

# ENCAPINFO
# -- exclude etc
# PREINSTALL
# -- etc files
# -- create etc/php.ini
# POSTINSTALL
# -- move etc files into place

###############################################################################
# spawn-fcgi

cd $ENCAP_TARGET/src
wget http://www.lighttpd.net/download/spawn-fcgi-1.6.3.tar.gz
tar xzvf spawn-fcgi-1.6.3.tar.gz
cd spawn-fcgi-1.6.3
./configure --prefix=$ENCAP_TARGET/encap/spawn-fcgi-1.6.3
make
make install

epkg spawn-fcgi
cd $ENCAP_TARGET/src/encap_pkgs
mkencap spawn-fcgi-1.6.3

# ENCAPINFO
# -- exclude etc
# PREINSTALL
# -- rc.d file
# POSTINSTALL
# -- move rc.d file into place

###############################################################################
# Memcached

# libevent
cd $ENCAP_TARGET/src
wget http://monkey.org/~provos/libevent-2.0.11-stable.tar.gz
tar xzvf libevent-2.0.11-stable.tar.gz
cd libevent-2.0.11-stable
./configure --prefix=$ENCAP_TARGET/encap/libevent-2.0.11
make
make install

epkg libevent
cd $ENCAP_TARGET/src/encap_pkgs
mkencap libevent-2.0.11

# memcached
cd $ENCAP_TARGET/src
wget http://memcached.googlecode.com/files/memcached-1.4.5.tar.gz
tar xzvf memcached-1.4.5.tar.gz
cd memcached-1.4.5
./configure --prefix=$ENCAP_TARGET/encap/memcached-1.4.5 --with-libevent=$ENCAP_TARGET
make
make install

epkg memcached
cd $ENCAP_TARGET/src/encap_pkgs
mkencap memcached-1.4.5

# libmemcached
cd $ENCAP_TARGET/src
wget http://launchpad.net/libmemcached/1.0/0.49/+download/libmemcached-0.49.tar.gz
tar xzvf libmemcached-0.49.tar.gz
cd libmemcached-0.49
export CFLAGS="-march=i686" # Fixes compile problem
./configure --prefix=$ENCAP_TARGET/encap/libmemcached-0.49
make
make install

epkg libmemcached
cd $ENCAP_TARGET/src/encap_pkgs
mkencap libmemcached-0.49

#gem install memcache-client memcached --no-rdoc --no-ri

###############################################################################
# Erlang

cd $ENCAP_TARGET/src
wget http://www.erlang.org/download/otp_src_R14B03.tar.gz
tar xzvf otp_src_R14B03.tar.gz
cd otp_src_R14B03
./configure --prefix=$ENCAP_TARGET/encap/erlang-R14B03 #--enable-darwin-64bit # Mac OS X >=10.6
make
make install

epkg erlang
cd $ENCAP_TARGET/src/encap_pkgs
mkencap erlang-R14B03

###############################################################################
# CouchDB (requires erlang, icu4c, curl, spidermonkey)

# curl
cd $ENCAP_TARGET/src
wget http://curl.haxx.se/download/curl-7.21.6.tar.gz
tar xzvf curl-7.21.6.tar.gz
cd curl-7.21.6
./configure --prefix=$ENCAP_TARGET/encap/curl-7.21.6
make
make install

epkg curl
cd $ENCAP_TARGET/src/encap_pkgs
mkencap curl-7.21.6

# icu
cd $ENCAP_TARGET/src
wget http://download.icu-project.org/files/icu4c/4.8/icu4c-4_8-src.tgz
tar xzvf icu4c-4_8-src.tgz
cd icu/source
./configure --prefix=$ENCAP_TARGET/encap/icu4c-4.8
#./runConfigureICU MacOSX --prefix=$ENCAP_TARGET/encap/icu4c-4.8 --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
make
make install

epkg icu4c
cd $ENCAP_TARGET/src/encap_pkgs
mkencap icu4c-4.8

# SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz.
# But we'll use the latest standalone version.

cd $ENCAP_TARGET/src
wget http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
tar js185-1.0.0.tar.gz
cd js-1.8.5/js/src
./configure --prefix=$ENCAP_TARGET/encap/js-1.8.5
make
make install

epkg js
cd $ENCAP_TARGET/src/encap_pkgs
mkencap js-1.8.5

# couchdb
export LD_RUN_PATH=$ENCAP_TARGET/lib # This is going to be a little tricky with encap

cd $ENCAP_TARGET/src
wget http://mirror.cc.columbia.edu/pub/software/apache/couchdb/1.0.2/apache-couchdb-1.0.2.tar.gz
tar xzvf apache-couchdb-1.0.2.tar.gz
cd apache-couchdb-1.0.2
./configure --prefix=$ENCAP_TARGET/encap/couchdb-1.0.2 --with-erlang=$ENCAP_TARGET/lib/erlang/usr/include --with-js-lib=$ENCAP_TARGET/lib --with-js-include=$ENCAP_TARGET/include
make
make install

epkg couchdb
cd $ENCAP_TARGET/src/encap_pkgs
mkencap couchdb-1.0.2
