#!/bin/sh

# This script contains some additional software.

. $HOME/.bash_profile

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
# Memcached

getunpack https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz
buildinstall libevent-2.0.21-stable

getunpack http://memcached.googlecode.com/files/memcached-1.4.15.tar.gz
buildinstall memcached-1.4.15

# (20130413 Not necessary, memcached gem install without libmemcached)
# [!] Getting a compile error for libmemcached, missing tr1/cinttypes.
# !!! Try installing second ruby gem before attempting to install this. If it works, this isn't necessary.
#getunpack https://launchpad.net/libmemcached/1.0/1.0.17/+download/libmemcached-1.0.17.tar.gz
#export CFLAGS="-march=i686" # Fixes compile problem (Remove on 64-bit) [Old, don't know 
#buildinstall libmemcached-1.0.17

# All ruby memcached client
gem install memcache-client --no-rdoc --no-ri

# Fast client with lots of C, but does not have drop-in support for rails
gem install memcached --no-rdoc --no-ri

# May need to execute the following on some systems like ArchLinux. It's not
# necessary on WebFaction machines, but it doesn't hurt to try.
ldconfig $PREFIX/lib

###############################################################################
# PHP

getunpack http://www.php.net/distributions/php-5.4.14.tar.gz
buildinstall php-5.4.14 --with-mysql --with-zlib --with-gettext --with-gdbm

# To avoid time zone warnings
cat > $PREFIX/etc/php.ini << EOF
[date]
date.timezone = "America/New_York"
EOF

###############################################################################
# spawn-fcgi

getunpack http://www.lighttpd.net/download/spawn-fcgi-1.6.3.tar.gz
buildinstall spawn-fcgi-1.6.3

###############################################################################
# Erlang

getunpack http://www.erlang.org/download/otp_src_R16B.tar.gz
buildinstall otp_src_R16B #--enable-darwin-64bit # Mac OS X >=10.6

###############################################################################
# CouchDB (requires Erlang)

getunpack http://curl.haxx.se/download/curl-7.30.0.tar.gz
buildinstall curl-7.30.0

getunpack http://download.icu-project.org/files/icu4c/51.1/icu4c-51_1-src.tgz
# cd icu/source && ./runConfigureICU MacOSX --prefix=$PREFIX --with-library-bits=64 --disable-samples --enable-static # Mac OS X >=10.6
buildinstall icu/source

# Mozilla SpiderMonkey
# The latest source is in http://hg.mozilla.org/mozilla-central/archive/tip.tar.gz.
# But we'll use the latest standalone version.

getunpack http://ftp.mozilla.org/pub/mozilla.org/js/mozjs17.0.0.tar.gz
buildinstall mozjs17.0.0/js/src

# Make sure couchdb is linked to the libraries it depends on.
# I used to have "export LD_LIBRARY_PATH=$PREFIX/lib", but this is hackish.
# And you would have to either run it before couchdb or put it in .bashrc,
# which is really bad idea. Google "LD_LIBRARY_PATH bad". It caused problems
# for me with other programs, which is why I needed to find a better solution.

# Note to self:
# This doesn't seem to help on Mac OS X, though. The best solution is to add
# "export DYLD_LIBRARY_PATH=$PREFIX/lib" (expanding $PREFIX) at the beginning of
# $PREFIX/bin/couchdb, which is actually just a shell script.

export LD_RUN_PATH=$PREFIX/lib # Works on WebFaction!

getunpack http://apache.cs.utah.edu/couchdb/source/1.3.0/apache-couchdb-1.3.0.tar.gz

# Getting error in CouchDB 1.1.1:
# couch_js/utf8.h:19:7: error: no newline at end of file
# So let's add that newline with:
#echo "" >> $PREFIX/src/apache-couchdb-1.1.1/src/couchdb/priv/couch_js/utf8.h

buildinstall apache-couchdb-1.3.0 --with-erlang=$PREFIX/lib/erlang/usr/include --with-js-lib=$PREFIX/lib --with-js-include=$PREFIX/include


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
