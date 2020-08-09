#!/bin/bash

set -e
#
#
# Create infrastructure-agent docker image and push it to Registry
#
#
AGENT_BUILD_NUMBER=${TAG:1}
NS=jportasa

echo "===> Downloading newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz from GH"
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz"
mkdir -p /${REPO_FULL_NAME}/target/bin/linux_amd64
curl -SL $URL | tar xz -C /${REPO_FULL_NAME}/target/bin/linux_amd64

echo "===> Running Makefile"
cd /${REPO_FULL_NAME}/build/container
make build/base

echo "===> Push image to dockerhub registry"
docker login --username ${DOCKERHUB_USERNAME} --password ${DOCKERHUB_PASSWORD}
docker push $NS/infrastructure