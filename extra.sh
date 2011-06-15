#!/bin/sh

# This script contains some additional software.

. $HOME/.bash_profile

###############################################################################
# Memcached

cd $PREFIX/src
wget http://monkey.org/~provos/libevent-2.0.11-stable.tar.gz
tar xzvf libevent-2.0.11-stable.tar.gz
cd libevent-2.0.11-stable
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
wget http://launchpad.net/libmemcached/1.0/0.49/+download/libmemcached-0.49.tar.gz
tar xzvf libmemcached-0.49.tar.gz
cd libmemcached-0.49
export CFLAGS="-march=i686" # Fixes compile problem (Remove on 64-bit)
./configure --prefix=$PREFIX
make
make install

# All ruby memcached client
gem install memcache-client --no-rdoc --no-ri

# Fast client with lots of C, but does not have drop-in support for rails
gem install memcached --no-rdoc --no-ri

# May need to execute the following on some systems like ArchLinux. It's not
# necessary on WebFaction machines, but it doesn't hurt to try.
ldconfig $PREFIX/lib

###############################################################################
# PHP

cd $PREFIX/src
wget http://us.php.net/get/php-5.3.6.tar.gz/from/this/mirror
tar xzvf php-5.3.6.tar.gz
cd php-5.3.6
./configure --prefix=$PREFIX --with-mysql --with-zlib --with-gettext --with-gdbm
make
make install

# To avoid time zone warnings
cat > $PREFIX/etc/php.ini << EOF
[date]
date.timezone = "America/New_York"
EOF

###############################################################################
# spawn-fcgi

cd $PREFIX/src
wget http://www.lighttpd.net/download/spawn-fcgi-1.6.3.tar.gz
tar xzvf spawn-fcgi-1.6.3.tar.gz
cd spawn-fcgi-1.6.3
./configure --prefix=$PREFIX
make
make install

###############################################################################
# Erlang R14B03

cd $PREFIX/src
wget http://www.erlang.org/download/otp_src_R14B03.tar.gz
tar xzvf otp_src_R14B03.tar.gz
cd otp_src_R14B03
./configure --prefix=$PREFIX #--enable-darwin-64bit # Mac OS X >=10.6
make
make install

###############################################################################
# CouchDB (requires Erlang)

cd $PREFIX/src
wget http://curl.haxx.se/download/curl-7.21.6.tar.gz
tar xzvf curl-7.21.6.tar.gz
cd curl-7.21.6
./configure --prefix=$PREFIX
make
make install

cd $PREFIX/src
wget http://download.icu-project.org/files/icu4c/4.8/icu4c-4_8-src.tgz
tar xzvf icu4c-4_8-src.tgz
cd icu/source
./configure --prefix=$PREFIX
#./runConfigureICU MacOSX --prefix=$PREFIX --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
make
make install

# Mozilla SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz.
# But we'll use the latest standalone version.

cd $PREFIX/src
wget http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
tar xzvf js185-1.0.0.tar.gz
cd js-1.8.5/js/src
./configure --prefix=$PREFIX
make
make install

# Make sure couchdb is linked to the libraries it depends on.
# I used to have "export LD_LIBRARY_PATH=$PREFIX/lib", but this is hackish.
# And you would have to either run it before couchdb or put it in .bashrc,
# which is really bad idea. Google "LD_LIBRARY_PATH bad". It caused problems
# for me with other programs, which is why I needed to find a better solution.

# Note to self:
# This doesn't seem to help on Mac OS X, though. The best solution is to add
# "export DYLD_LIBRARY_PATH=$PREFIX/lib" (expanding $PREFIX) at the beginning of
# $PREFIX/bin/erlang, which is actually just a shell script.

export LD_RUN_PATH=$PREFIX/lib # Works on WebFaction!

cd $PREFIX/src
wget http://mirror.cc.columbia.edu/pub/software/apache//couchdb/1.1.0/apache-couchdb-1.1.0.tar.gz
tar xzvf apache-couchdb-1.1.0.tar.gz
cd apache-couchdb-1.1.0
./configure --prefix=$PREFIX --with-erlang=$PREFIX/lib/erlang/usr/include --with-js-lib=$PREFIX/lib --with-js-include=$PREFIX/include
make
make install



###############################################################################

# Monit file for memcached
cat > $PREFIX/etc/monit/memcached.monitrc << EOF
check process memcached
	with pidfile $PREFIX/var/run/memcached.pid
	start program "$PREFIX/bin/memcached -d -m 10 -s $PREFIX/var/tmp/memcached.sock -P $PREFIX/var/run/memcached.pid"
	stop program "$PREFIX/etc/rc.d/memcached-stop"
	if totalmem > 25.0 MB for 5 cycles then restart
	if failed unixsocket $PREFIX/var/tmp/memcached.sock then restart
	if cpu usage > 95% for 3 cycles then restart
	if 5 restarts within 5 cycles then timeout
	group memcached
EOF

# This script is the only way to stop memcached it and remove the pid file.
# I had problems with this in the monitrc file.
cat > $PREFIX/etc/rc.d/memcached-stop << EOF
#!/bin/sh

/usr/bin/killall -u $USER memcached
/bin/rm $PREFIX/var/run/memcached.pid
EOF

chmod 755 $PREFIX/etc/rc.d/memcached-stop

# Monit file for php-cgi
cat > $PREFIX/etc/monit/php-cgi.monitrc << EOF
check process php-cgi
  with pidfile $PREFIX/var/run/fastcgi-php.pid
  start program "$PREFIX/bin/spawn-fcgi -s $PREFIX/var/tmp/fastcgi.sock -P $PREFIX/var/run/fastcgi-php.pid -d $PREFIX/etc -- $PREFIX/bin/php-cgi"
  stop program "$PREFIX/etc/rc.d/php-cgi-stop"
  if totalmem > 50.0 MB for 5 cycles then restart
  if failed unixsocket $PREFIX/var/tmp/fastcgi.sock then restart
  if cpu usage > 95% for 3 cycles then restart
  if 5 restarts within 5 cycles then timeout
  group php-cgi
EOF

# This script is the only way to stop php-cgi and remove the pid file.
# I had problems with this in the monitrc file.
cat > $PREFIX/etc/rc.d/php-cgi-stop << EOF
#!/bin/sh

/bin/kill `/bin/cat $PREFIX/var/run/fastcgi-php.pid`
/bin/rm $PREFIX/var/run/fastcgi-php.pid
EOF

chmod 755 $PREFIX/etc/rc.d/php-cgi-stop

# Monit file for couchdb (Replace port with your couchdb port)
cat > $PREFIX/etc/monit/couchdb.monitrc << EOF
check process couchdb
	with pidfile $PREFIX/var/run/couchdb/couchdb.pid
	start program "$PREFIX/etc/rc.d/couchdb-start"
	stop program "$PREFIX/bin/couchdb -d"
	if totalmem > 50.0 MB for 5 cycles then restart
	if failed port 5984 then restart
	if failed url http://localhost:5984/ and content == '"couchdb"' then restart
	if cpu usage > 95% for 3 cycles then restart
	if 5 restarts within 5 cycles then timeout
	group couchdb
EOF

cat > $PREFIX/etc/rc.d/couchdb-start << EOF
#!/bin/sh

export HOME=$HOME # Absolutely necessary for monit to start couchdb.
\$HOME/apps/bin/couchdb -b -o /dev/null -e /dev/null
EOF

chmod 755 $PREFIX/etc/rc.d/couchdb-start
