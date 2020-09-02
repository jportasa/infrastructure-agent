#!/bin/bash

set -e
#
#
# Create binary for harvest tests
#
#

echo "===> Creating harvest binaryfor Linux"
GOOS=linux
GOARCH=amd64
go test ./test/harvest -tags="harvest" -v -c -o ./harvest-bin

echo "===>Here is the binary harvest-bin"
ls -la