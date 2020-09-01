#!/bin/bash

set -e
#
#
# Create binary for harvest tests
#
#
GOOS=linux
GOARCH=amd64

echo "===> Creating harvest binary"
go test ./test/harvest -tags="harvest" -v -c -o ./harvest-bin

echo "===>Here is the binary harvest-bin"
ls -la