#!/usr/bin/env bash
#Assumes Arch Linux and yay AUR package installed
if [[ ! -d st ]];
then
    yay --getpkgbuild st;
fi;

sha256=$(openssl sha256 config.h | awk '{print $2}');
(
set -o errexit -o nounset -o pipefail;
cd st;
git pull;
cp ../config.h .;
rm -f *.*z;
makepkg --install --noconfirm;
);
