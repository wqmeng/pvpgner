#!/bin/sh
if  [ "$1" == "" ]; then
  VERSION=1.13c
else
  VERSION=$1
fi

dnf -qy clean all
dnf -qy update

dnf -qy install wget tmux gcc libX11-devel freetype-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel dbus-devel fontconfig-devel
dnf -qy groupinstall 'Development Tools'
dnf -qy install --assumeyes epel-release
dnf -qy install --assumeyes p7zip

mkdir -p /home/src
cd /home/src

# Wine 8 can not install on centos-stream-9 yet?
cd /tmp
wget -q https://dl.winehq.org/wine/source/8.x/wine-8.13.tar.xz
rm wine-8.13 -rf
tar -xf wine-8.13.tar.xz -C /tmp/

cd /tmp/wine-8.13/

dnf -qy install glibc-devel.i686
dnf -qy install gnutls-devel.i686

#./configure --enable-win64
# ./configure --enable-win64 --without-x --without-freetype --disable-win16
make -s distclean

./configure --without-x --without-freetype --disable-win16
#tmux
make -sj 4
make install

wine --version

WINEPREFIX=~/.wine WINEARCH="win32" wine winecfg

# 后面添加具体的服务器的版本文件.
# wget -qO diablo2_bnet.7z "http://10.0.0.10/diablo2_bnet.7z"
# 7za x -y diablo2_bnet.7z

cd /home
rm /home/pvpgn -rf
rm /home/d2gs -rf
# mkdir -p /home/pvpgn

wget -q https://github.com/wqmeng/pvpgner/raw/main/pvpgn/pvpgn1.99.8.0.0-rc1-PRO.7z
7za x -y pvpgn1.99.8.0.0-rc1-PRO.7z
mv pvpgn1.99.8.0.0-rc1-PRO pvpgn
# rm pvpgn1.99.8.0.0-rc1-PRO -rf
#rm pvpgn1.99.8.0.0-rc1-PRO.7z -rf

cd /home/pvpgn
wget -q https://raw.githubusercontent.com/wqmeng/pvpgner/main/src/config_pvpgn.sh
chmod +x config_pvpgn.sh
# change the conf files and reg files if needed