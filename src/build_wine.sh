#!/bin/sh
if  [ "$1" == "" ]; then
  D2VERSION=1.13c
else
  D2VERSION=$1
fi

dnf -yq clean all
dnf -yq update

dnf -yq install wget tmux gcc libX11-devel freetype-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel dbus-devel fontconfig-devel
dnf -yq groupinstall 'Development Tools'
dnf -yq install --assumeyes epel-release
dnf -yq install --assumeyes p7zip
dnf -yq install glibc-devel.i686
dnf -yq install gnutls-devel.i686
mkdir -p /home/src
cd /home/src

# Build wine 8 from source
cd /tmp
wget -q https://dl.winehq.org/wine/source/8.x/wine-8.13.tar.xz
rm wine-8.13 -rf
tar -xf wine-8.13.tar.xz -C /tmp/
cd /tmp/wine-8.13/
# ./configure --enable-win64 --without-x --without-freetype --disable-win16
make -s distclean

./configure --without-x --without-freetype --disable-win16
make -sj 4
make install

wine --version
WINEPREFIX=~/.wine WINEARCH="win32" wine winecfg

wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
dnf -yq install jq