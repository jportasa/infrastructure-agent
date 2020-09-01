#!/bin/bash

set -e
#
#
# Create binary for harvest tests
#
#
GOOS=linux
GOARCH=amd64
BINARY_NAME='harvest-binary'

echo "===> Creating harvest binary"
go test github.com/${REPO_FULL_NAME}/test/harvest -tags="harvest" -v -c -o ${BINARY_NAME}