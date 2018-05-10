#!/usr/bin/env bash
#Assumes Arch Linux and yay AUR package installed
yay --getpkgbuild st;
sha256=$(openssl sha256 config.h | awk '{print $2}');
pushd st || exit;
cp ../config.h .;
sed -i '16s/.*/'"'$sha256')"'/' PKGBUILD;
makepkg;
makepkg --install --noconfirm;
popd || exit;
rm -rf st;
