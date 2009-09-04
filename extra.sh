# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-1.4.12-stable.tar.gz
tar xzvf libevent-1.4.12-stable.tar.gz
cd libevent-1.4.12-stable
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://www.danga.com/memcached/dist/memcached-1.4.1.tar.gz
tar xzvf memcached-1.4.1.tar.gz
cd memcached-1.4.1
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.tangent.org/libmemcached-0.31.tar.gz
tar xzvf libmemcached-0.31.tar.gz
cd libmemcached-0.31
./configure --prefix=$PREFIX
make
make install

# All ruby memcached client
gem install memcache-client

# Fast client with lots of C, but does not have drop-in support for rails
# Also dependent of specific libmemcached version
gem install memcached

# May need to execute the following on some systems like ArchLinux. It's not
# necessary on WebFaction machines, but it doesn't hurt to try.
ldconfig $PREFIX/lib

###############################################################################
# Erlang R13B01

cd $PREFIX/src
wget http://erlang.org/download/otp_src_R13B01.tar.gz
tar xzvf otp_src_R13B01.tar.gz
cd otp_src_R13B01
./configure --prefix=$PREFIX
make
make install

###############################################################################
# CouchDB

# Mozilla SpiderMonkey
cd $PREFIX/src
wget http://ftp.mozilla.org/pub/mozilla.org/js/js-1.8.0-rc1.tar.gz
tar xzvf js-1.8.0-rc1.tar.gz
cd js/src
make -f Makefile.ref
JS_DIST=$PREFIX/spidermonkey make -f Makefile.ref export

export LD_LIBRARY_PATH=$PREFIX/spidermonkey/lib # Linux
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$PREFIX/spidermonkey/lib # Mac OS X

cd $PREFIX/src
wget http://download.icu-project.org/files/icu4c/4.3.1/icu4c-4_3_1-src.tgz
tar xzvf icu4c-4_3_1-src.tgz
cd icu/source
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://www.apache.org/dyn/closer.cgi?path=/couchdb/0.9.1/apache-couchdb-0.9.1.tar.gz
tar xzvf apache-couchdb-0.9.1.tar.gz
cd apache-couchdb-0.9.1
./configure --prefix=$PREFIX --with-erlang=$PREFIX/lib/erlang/usr/include --with-js-lib=$PREFIX/spidermonkey/lib --with-js-include=$PREFIX/spidermonkey/include
make
make install