# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-1.4.13-stable.tar.gz
tar xzvf libevent-1.4.13-stable.tar.gz
cd libevent-1.4.13-stable
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://memcached.googlecode.com/files/memcached-1.4.5.tar.gz
tar xzvf memcached-1.4.5.tar.gz
cd memcached-1.4.5
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.tangent.org/libmemcached-0.38.tar.gz
tar xzvf libmemcached-0.38.tar.gz
cd libmemcached-0.38
export CFLAGS="-march=i686" # Fixes compile problem found in 0.38
./configure --prefix=$PREFIX
make
make install

# All ruby memcached client
gem install memcache-client --no-rdoc --no-ri

# Fast client with lots of C, but does not have drop-in support for rails
# Also dependent of specific libmemcached version
gem install memcached --no-rdoc --no-ri

# May need to execute the following on some systems like ArchLinux. It's not
# necessary on WebFaction machines, but it doesn't hurt to try.
ldconfig $PREFIX/lib

###############################################################################
# Erlang R13B04

cd $PREFIX/src
wget http://www.erlang.org/download/otp_src_R13B04.tar.gz
tar xzvf otp_src_R13B04.tar.gz
cd otp_src_R13B04
./configure --prefix=$PREFIX #--enable-darwin-64bit # Mac OS X >=10.6
make
make install

###############################################################################
# CouchDB (requires Erlang)

# Mozilla SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz

cd $PREFIX/src
wget http://ftp.mozilla.org/pub/mozilla.org/js/js-1.8.0-rc1.tar.gz
tar xzvf js-1.8.0-rc1.tar.gz
cd js/src
make -f Makefile.ref
JS_DIST=$PREFIX make -f Makefile.ref export

# This needs to be added to .bashrc
export LD_LIBRARY_PATH=$PREFIX/lib # Linux
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$PREFIX/lib # Mac OS X

cd $PREFIX/src
wget http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-src.tgz
tar xzvf icu4c-4_4_1-src.tgz
cd icu/source
./configure --prefix=$PREFIX
#./runConfigureICU MacOSX --prefix=$PREFIX --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
make
make install

cd $PREFIX/src
wget http://curl.haxx.se/download/curl-7.20.1.tar.gz
tar xzvf curl-7.20.1.tar.gz
cd curl-7.20.1
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://mirror.its.uidaho.edu/pub/apache/couchdb/0.11.0/apache-couchdb-0.11.0.tar.gz
tar xzvf apache-couchdb-0.11.0.tar.gz
cd apache-couchdb-0.11.0
./configure --prefix=$PREFIX --with-erlang=$PREFIX/lib/erlang/usr/include --with-js-lib=$PREFIX/lib --with-js-include=$PREFIX/include
make
make install

# CouchDB 0.11.0 isn't working. Getting an error at startup 
# "/home/rzownir/apps/etc/couchdb/default.ini"
# "/home/rzownir/apps/etc/couchdb/local.ini"
# "libicuuc.so.44: cannot open shared object file: No such file or directory"