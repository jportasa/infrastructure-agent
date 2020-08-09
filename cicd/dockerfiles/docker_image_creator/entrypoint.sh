#!/bin/bash

set -e
#
#
# Create infrastructure-agent docker image and push it to Registry
#
#
export image_version=${TAG:1}
export agent_version=${TAG:1}
export agent_bin='newrelic/infrastructure'

echo "===> Downloading newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz from GH"
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz"
mkdir -p /${REPO_FULL_NAME}/target/bin/linux_amd64
curl -SL $URL | tar xz -C /${REPO_FULL_NAME}/target/bin/linux_amd64

echo "===> Running Makefile"
cd /${REPO_FULL_NAME}/build/container
make build/base

#echo "===> Push image to registry"
#docker login