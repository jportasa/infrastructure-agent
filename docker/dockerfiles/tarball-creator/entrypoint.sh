#!/bin/bash

set -e
#
#
# Create Tarball for Linux and push it to GH Release Assets
#
#
echo "===> Downloading Tarball binaries from GH"
env
TAG_WITHOUT_V=$(echo $TAG | cut -d "v" -f 2)
cd /${REPO_FULL_NAME}
mkdir binaries && cd binaries
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG_WITHOUT_V}_amd64.tar.gz"
echo "URL=$URL"
echo "REPO_FULL_NAME=$REPO_FULL_NAME"
wget $URL -O - | tar -xz --strip 1

echo "===> Creating Tarball"
cd /${REPO_FULL_NAME}
mkdir -p tarball/newrelic-infra && cd tarball/newrelic-infra
mkdir -p etc/{newrelic-infra/integrations.d,init_scripts/{systemd,sysv,upstart}}
mkdir -p usr/bin
mkdir -p var/{db,log/newrelic-infra,run/newrelic-infra}

cp /${REPO_FULL_NAME}/build/package/binaries/linux/config_defaults.sh .
cp /${REPO_FULL_NAME}/build/package/systemd/newrelic-infra.service etc/init_scripts/systemd/
cp /${REPO_FULL_NAME}/build/package/sysv/deb/newrelic-infra  etc/init_scripts/sysv/
cp /${REPO_FULL_NAME}/build/package/upstart/newrelic-infra  etc/init_scripts/upstart/
cp /${REPO_FULL_NAME}/build/package/binaries/linux/installer.sh .
cp /${REPO_FULL_NAME}/binaries/* usr/bin/
cp /${REPO_FULL_NAME}/LICENSE LICENSE.txt

cd /${REPO_FULL_NAME}/tarball
tar -czvf newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz *


echo "===> Uploading GitHub asset newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz to TAG=$TAG"
filename=newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz
release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )
curl \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @$filename \
    "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"
