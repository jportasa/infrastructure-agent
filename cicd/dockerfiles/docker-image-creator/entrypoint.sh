#!/bin/bash

set -e
#
#
# Create infrastructure-agent docker image and push it to Registry
#
#
if ( $PRERELEASE ); then
  export AGENT_BUILD_NUMBER=${TAG:1}-rc
else
  export AGENT_BUILD_NUMBER=${TAG:1}
fi

echo "===> Downloading newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz from GH"
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz"
mkdir -p /${REPO_FULL_NAME}/target/bin/linux_amd64
curl -SL $URL | tar xz -C /${REPO_FULL_NAME}/target/bin/linux_amd64

echo "===> Running Makefile to create docker image"
cd /${REPO_FULL_NAME}/build/container
make build/base

docker login --username ${DOCKERHUB_USERNAME} --password ${DOCKERHUB_PASSWORD}
if ( $PRERELEASE ); then
  echo "===> Push release candidate image to dockerhub registry"
  docker push $DOCKERHUB_NAMESPACE/infrastructure:${TAG:1}-rc
else
  echo "===> Push release image to dockerhub registry"
  docker push $DOCKERHUB_NAMESPACE/infrastructure:latest
  docker push $DOCKERHUB_NAMESPACE/infrastructure:${TAG:1}
fi