#!/usr/bin/env bash
#Assumes Arch Linux and yay AUR package installed
if [[ ! -d st ]];
then
    yay --getpkgbuild st;
fi;

sha256=$(openssl sha256 config.h | awk '{print $2}');
pushd st || exit;
git pull;
cp ../config.h .;
sed -i '16s/.*/'"'$sha256')"'/' PKGBUILD;
rm -f *.*z;
makepkg;
makepkg --install --noconfirm;
popd || exit;