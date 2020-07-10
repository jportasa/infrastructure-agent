#!/bin/bash

set -e

NRI_DOCKER_VERSION=1.3.0
NRI_DOCKER_ARCH=amd64
# NRI_FLEX_VERSION=1.3.1
# NRI_FLEX_OS=Linux
# NRI_FLEX_ARCH=x86_64

echo "===> Get binaries from other repos and put them in binaries/"
mkdir -p /tmp/binaries/{nri-docker,nri-flex}
curl -SL "https://download.newrelic.com/infrastructure_agent/binaries/linux/${NRI_DOCKER_ARCH}/nri-docker_linux_${NRI_DOCKER_VERSION}_${NRI_DOCKER_ARCH}.tar.gz" | tar xz -C /tmp/binaries/nri-docker
# curl -SL "https://github.com/newrelic/nri-flex/releases/download/v${NRI_FLEX_VERSION}/nri-flex_${NRI_FLEX_VERSION}_${NRI_FLEX_OS}_x86_64.tar.gz" | tar xz -C /tmp/binaries/nri-flex

echo "===> Importing GPG private key from GHA secrets..."
printf %s ${GPG_PRIVATE_KEY} | base64 -d | gpg --batch --import -

echo "===> List GPG keys"
gpg --list-keys

echo "===> Check if there are already .deb release assets in GH"
release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )
download_urls=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets | jq --raw-output '.[].browser_download_url' | grep .deb >/dev/null 2>&1 || echo 'empty')

echo "===> Strip from TAG v character"
TAG=`echo ${TAG:1}`

if $GITHUB_PUSH_RELEASE_ASSETS; then
  if [ $download_urls == 'empty' ]; then
    echo "===> No GH Release Assets, so I run Goreleaser and push to GH release assets";
    goreleaser release --config=.goreleaser.yml --rm-dist
  else
    echo "===> Release assets were already created for this TAG, GH don't allow to overwrite them"
  fi
else
    echo "===> Run Goreleaser and push them to GH Workflow Cache Assets";
    goreleaser release --config=.goreleaser.yml --rm-dist --snapshot
fi
