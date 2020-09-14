#!/bin/bash
#
#
# Sign binaries in dirs that begin with "DIR_SUFIX"
#
#
DIR_SUFIX=$1

echo "===> List GPG keys"
gpg --list-keys

for search_dir in $(ls -d ${DIR_SUFIX}*); do
	for entry in "$search_dir"/*
	do
	  echo "===> Signing binary $entry"
	   gpg --pinentry-mode loopback --passphrase 'newrelic' --batch --yes --sign $entry
	done
done