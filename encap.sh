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
wget http://kernel.org/pub/software/scm/git/git-1.7.2.3.tar.gz
tar xzvf git-1.7.2.3.tar.gz
cd git-1.7.2.3
./configure --prefix=$ENCAP_TARGET/encap/git-1.7.2.3
make all
make install

cd $ENCAP_TARGET/encap/git-1.7.2.3/share/man
wget http://kernel.org/pub/software/scm/git/git-manpages-1.7.2.3.tar.gz
tar xzvf git-manpages-1.7.2.3.tar.gz
rm git-manpages-1.7.2.3.tar.gz

epkg git
cd $ENCAP_TARGET/src/encap_pkgs
mkencap git-1.7.2.3

###############################################################################
# SQLite3

cd $ENCAP_TARGET/src
wget http://www.sqlite.org/sqlite-amalgamation-3.7.2.tar.gz
tar xzvf sqlite-amalgamation-3.7.2.tar.gz
cd sqlite-3.7.2
./configure --prefix=$ENCAP_TARGET/encap/sqlite-3.7.2
make
make install

epkg sqlite
cd $ENCAP_TARGET/src/encap_pkgs
mkencap sqlite-3.7.2

###############################################################################
# Ruby

cd $ENCAP_TARGET/src
wget ftp://ftp.ruby-lang.org//pub/ruby/1.9/ruby-1.9.2-p0.tar.gz
tar xzvf ruby-1.9.2-p0.tar.gz
cd ruby-1.9.2-p0
./configure --prefix=$ENCAP_TARGET/encap/ruby-1.9.2_p0 --disable-install-doc # Using _ instead of - to comform with encap specs
make
make install

epkg ruby
cd $ENCAP_TARGET/src/encap_pkgs
mkencap ruby-1.9.2_p0

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
wget http://www.openssl.org/source/openssl-1.0.0a.tar.gz
tar xzvf openssl-1.0.0a.tar.gz
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.10.tar.gz
tar xzvf pcre-8.10.tar.gz
wget http://zlib.net/zlib-1.2.5.tar.gz
tar xzvf zlib-1.2.5.tar.gz
wget http://nginx.org/download/nginx-0.8.50.tar.gz
tar xzvf nginx-0.8.52.tar.gz
git clone git://github.com/gnosek/nginx-upstream-fair.git nginx-upstream-fair
cd nginx-0.8.52
./configure \
--with-pcre=$ENCAP_TARGET/src/pcre-8.10 \
--with-zlib=$ENCAP_TARGET/src/zlib-1.2.5 \
--with-openssl=$ENCAP_TARGET/src/openssl-1.0.0a \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_realip_module \
--add-module=$ENCAP_TARGET/src/nginx-upstream-fair \
--add-module=$PASSENGER_ROOT/ext/nginx \
--prefix=$ENCAP_TARGET/encap/nginx-0.8.52 \
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

rm -rf $ENCAP_TARGET/encap/nginx-0.8.52/html
mkdir $ENCAP_TARGET/encap/nginx-0.8.52/etc
mv $ENCAP_TARGET/etc/nginx $ENCAP_TARGET/encap/nginx-0.8.52/etc

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
mkencap nginx-0.8.52

###############################################################################
# Monit

cd $ENCAP_TARGET/src
wget http://mmonit.com/monit/dist/monit-5.1.1.tar.gz
tar xzvf monit-5.1.1.tar.gz
cd monit-5.1.1
./configure --prefix=$ENCAP_TARGET/encap/monit-5.1.1
make
make install

epkg monit
cd $ENCAP_TARGET/src/encap_pkgs
mkencap monit-5.1.1


# PREINSTALL SCRIPT
# -- RC.D FILE
# POSTINSTALL SCRIPT
# -- ETC copy if nec
# ENCAPINFO
# -- excl etc

###############################################################################
# PHP

cd $ENCAP_TARGET/src
wget http://us.php.net/get/php-5.3.3.tar.gz/from/this/mirror
tar xzvf php-5.3.3.tar.gz
cd php-5.3.3
./configure --prefix=$ENCAP_TARGET/encap/php-5.3.3 --with-mysql --with-zlib --with-gettext --with-gdbm
make
make install

epkg php
cd $ENCAP_TARGET/src/encap_pkgs
mkencap php-5.3.3

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
wget http://monkey.org/~provos/libevent-1.4.13-stable.tar.gz
tar xzvf libevent-1.4.13-stable.tar.gz
cd libevent-1.4.13-stable
./configure --prefix=$ENCAP_TARGET/encap/libevent-1.4.13
make
make install

epkg libevent
cd $ENCAP_TARGET/src/encap_pkgs
mkencap libevent-1.4.13

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
wget http://launchpad.net/libmemcached/1.0/0.43/+download/libmemcached-0.43.tar.gz
tar xzvf libmemcached-0.43.tar.gz
cd libmemcached-0.43
export CFLAGS="-march=i686" # Fixes compile problem
./configure --prefix=$ENCAP_TARGET/encap/libmemcached-0.43
make
make install

epkg libmemcached
cd $ENCAP_TARGET/src/encap_pkgs
mkencap libmemcached-0.43

#gem install memcache-client memcached --no-rdoc --no-ri

###############################################################################
# Erlang

cd $ENCAP_TARGET/src
wget http://www.erlang.org/download/otp_src_R14B.tar.gz
tar xzvf otp_src_R14B.tar.gz
cd otp_src_R14B
./configure --prefix=$ENCAP_TARGET/encap/erlang-R14B #--enable-darwin-64bit # Mac OS X >=10.6
make
make install

epkg erlang
cd $ENCAP_TARGET/src/encap_pkgs
mkencap erlang-R14A

###############################################################################
# CouchDB (requires erlang, icu4c, curl, spidermonkey)

# curl
cd $ENCAP_TARGET/src
wget http://curl.haxx.se/download/curl-7.21.1.tar.gz
tar xzvf curl-7.21.1.tar.gz
cd curl-7.21.1
./configure --prefix=$ENCAP_TARGET/encap/curl-7.21.1
make
make install

epkg curl
cd $ENCAP_TARGET/src/encap_pkgs
mkencap curl-7.21.1

# icu
cd $ENCAP_TARGET/src
wget http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-src.tgz
tar xzvf icu4c-4_4_1-src.tgz
cd icu/source
./configure --prefix=$ENCAP_TARGET/encap/icu4c-4.4.1
#./runConfigureICU MacOSX --prefix=$ENCAP_TARGET/encap/icu4c-4.4.1 --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
make
make install

epkg icu4c
cd $ENCAP_TARGET/src/encap_pkgs
mkencap icu4c-4.4.1

# SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz.
# But we'll stick to the version last released independently and not buried inside
# a much larger project!

cd $ENCAP_TARGET/src
wget http://ftp.mozilla.org/pub/mozilla.org/js/js-1.8.0-rc1.tar.gz
tar xzvf js-1.8.0-rc1.tar.gz
cd js/src
make -f Makefile.ref
JS_DIST=$ENCAP_TARGET/encap/js-1.8.0_rc1 make -f Makefile.ref export

epkg js
cd $ENCAP_TARGET/src/encap_pkgs
mkencap js-1.8.0_rc1

# couchdb
export LD_RUN_PATH=$ENCAP_TARGET/lib # This is going to be a little tricky with encap

cd $ENCAP_TARGET/src
wget http://apache.ziply.com/couchdb/1.0.1/apache-couchdb-1.0.1.tar.gz
tar xzvf apache-couchdb-1.0.1.tar.gz
cd apache-couchdb-1.0.1
./configure --prefix=$ENCAP_TARGET/encap/couchdb-1.0.1 --with-erlang=$ENCAP_TARGET/lib/erlang/usr/include --with-js-lib=$ENCAP_TARGET/lib --with-js-include=$ENCAP_TARGET/include
make
make install

epkg couchdb
cd $ENCAP_TARGET/src/encap_pkgs
mkencap couchdb-1.0.1
