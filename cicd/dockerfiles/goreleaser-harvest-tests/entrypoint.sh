#!/bin/bash

set -e
#
#
# Run goreleaser to creeate tarball for harvest tests
#
#
echo "===> Importing GPG private key from GHA secrets..."
printf %s ${GPG_APT_PRIVATE_KEY} | base64 -d | gpg --batch --import -

echo "===> List GPG keys"
gpg --list-keys

TAG='0.0.0'

echo "===> Run Goreleaser";
goreleaser release --config=.goreleaser_harvest_tests.yml --rm-dist --snapshot
