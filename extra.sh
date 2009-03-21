# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-1.4.9-stable.tar.gz
tar xzvf libevent-1.4.9-stable.tar.gz
cd libevent-1.4.9-stable
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://www.danga.com/memcached/dist/memcached-1.2.6.tar.gz
tar xzvf memcached-1.2.6.tar.gz
cd memcached-1.2.6
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.tangent.org/libmemcached-0.26.tar.gz
tar xzvf libmemcached-0.26.tar.gz
cd libmemcached-0.26
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
# Erlang R12B-5
# There is a build error on Redhat/CentOS concerning ssl. The easy fix is to
# disable ssl support in Erlang. If some can get Erlang to build with SSL on
# WebFaction machines, PLEASE let me know how. I tried the solution on
# http://www.erlang.org/pipermail/erlang-bugs/2007-December/000562.html, but
# then got an error dealing with krb5. Maybe downloading and including the
# kerberos 5 source would solve the problem, but I've been messing around with
# with this too long.

cd $PREFIX/src
wget http://erlang.org/download/otp_src_R13A.tar.gz
tar xzvf otp_src_R13A.tar.gz
cd otp_src_R13A
./configure --prefix=$PREFIX --without-ssl
make
make install
