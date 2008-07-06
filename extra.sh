# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-1.4.5-stable.tar.gz
tar xzvf libevent-1.4.5-stable.tar.gz
cd libevent-1.4.5-stable
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://www.danga.com/memcached/dist/memcached-1.2.5.tar.gz
tar xzvf memcached-1.2.5.tar.gz
cd memcached-1.2.5
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.tangent.org/libmemcached-0.21.tar.gz
tar xzvf libmemcached-0.21.tar.gz
cd libmemcached-0.21
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