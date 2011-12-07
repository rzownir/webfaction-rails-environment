################################################################################
# Using rpm to manage packages in our private application environment

# Source: http://ajaya.name/?p=6353

# Step 1. Intialize your own private rpm db
mkdir -p $PREFIX/lib/rpm
rpm --initdb --root $PREFIX --dbpath lib/rpm

# Step 2. See what files are in the rpm and where they will be installed by
# default. Relocate the path to your rpm root directory.
rpm -qlp package.rpm

# This will list all the files in the rpm. If they all start with /usr, we can
# just use $PREFIX as the new path as shown below.

# Step 3. See if all dependent rpm met?
rpm -ivh package.rpm

# This will fail as you don't have permission to install. However if doesn't
# complain about dependent files then you are good. Otherwise, install the
# dependent rpms first.

# Step 4. Install the rpm
rpm --root $PREFIX --dbpath lib/rpm \
--relocate /usr=$PREFIX --nodeps -ivh package.rpm

# For rpms built for your home dir:
rpm --root $PREFIX --dbpath lib/rpm --nodeps -ivh package.rpm

# You have to add the flag --nodeps as the dependent rpms are in the system rpm
# database but not in your own.

# The following creates our own rpm file hierarchy and instructs rpm to save
# the rpms we create in our local hierarchy. Otherwise rpm will try (and fail)
# to write in a directory requiring superuser privileges.
# See: http://perso.b2b2c.ca/sarrazip/dev/rpm-building-crash-course.html
mkdir $PREFIX/rpm
cd $PREFIX/rpm
mkdir SOURCES SPECS BUILD SRPMS RPMS
cd RPMS
mkdir i386 athlon i486 i586 i686 noarch

cat > ~/.rpmmacros << EOF
%_topdir $PREFIX/rpm
EOF

################################################################################
# Now that we can use rpm to manage applications in our home directory, we can
# use checkinstall to build them from source and package them into rpm files.

# checkinstall 1.6.2
# Generates Debian, RPM, or Slackware packages after building packages from source.
# Provides install, tracking, and uninstall capabilities.
cd $PREFIX/src
wget http://asic-linux.com.mx/~izto/checkinstall/files/source/checkinstall-1.6.2.tar.gz
tar xzvf checkinstall-1.6.2.tar.gz
cd checkinstall-1.6.2
make
make install PREFIX=$PREFIX

# Usage:
# After make, instead of make install, do checkinstall -R --nodoc

# !!! SNAG !!!
# When you try to install the rpm, you get an error:
# error: unpacking of archive failed on file /home: cpio: chmod failed - Operation not permitted
# This is because it tries to create and chmod /home and /home/username, which
# you are not permitted to do.
#
# So for now, cannot install as regular user.
