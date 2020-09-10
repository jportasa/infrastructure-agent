#!/bin/bash
#
#
# Sign binaries in dirs that begin with "DIR_SUFIX"
#
#
DIR_SUFIX=$1

echo "===> Importing GPG private key from GHA secrets..."
printf %s ${GPG_APT_PRIVATE_KEY} | base64 -d | gpg --batch --import -
echo "===> List GPG keys"
gpg --list-keys
echo "===> Sign the binary $FILE_TO_SIGN"
gpg --sign $FILE_TO_SIGN

for search_dir in $(ls -d ${DIR_SUFIX}*); do
	for entry in "$search_dir"/*
	do
	  echo "===> Signing binary $entry"
	  echo $entry
	done
done