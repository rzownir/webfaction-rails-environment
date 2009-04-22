# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-1.4.10-stable.tar.gz
tar xzvf libevent-1.4.10-stable.tar.gz
cd libevent-1.4.10-stable
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://www.danga.com/memcached/dist/memcached-1.2.8.tar.gz
tar xzvf memcached-1.2.8.tar.gz
cd memcached-1.2.8
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.tangent.org/libmemcached-0.28.tar.gz
tar xzvf libmemcached-0.28.tar.gz
cd libmemcached-0.28
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
# Erlang R13B

cd $PREFIX/src
wget http://erlang.org/download/otp_src_R13B.tar.gz
tar xzvf otp_src_R13B.tar.gz
cd otp_src_R13B
./configure --prefix=$PREFIX
make
make install
