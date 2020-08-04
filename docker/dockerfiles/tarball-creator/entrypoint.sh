#!/bin/bash

set -e

#
#
# Create Tarball for Linux and push it to GH Release Assets
#
#
TAG='v0.0.44'
REPO_FULL_NAME='jportasa/infrastructure-agent'
sleep 10000

echo "===> Downloading Tarball binaries from Github"

release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )
download_url=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets | jq --raw-output '.[].browser_download_url' | grep newrelic-infra_binaries )
cd /${REPO_FULL_NAME}
mkdir binaries && cd binaries
wget ${download_url} -O - | tar -xz

echo "===> Creating Tarball"
cd /${REPO_FULL_NAME}
mkdir -p tarball/newrelic-infra && cd tarball/newrelic-infra
mkdir -p etc/{newrelic-infra/integrations.d,init_scripts/{systemd,sysv,upstart}}
mkdir -p usr/bin
mkdir -p var/{db,log/newrelic-infra,run/newrelic-infra}

cp /${REPO_FULL_NAME}/config_defaults.sh .
cp /${REPO_FULL_NAME}/build/package/systemd/newrelic-infra.service etc/init_scripts/systemd/
cp /${REPO_FULL_NAME}/build/package/sysv/deb/newrelic-infra  etc/init_scripts/sysv/
cp /${REPO_FULL_NAME}/build/package/upstart/newrelic-infra  etc/init_scripts/upstart/
cp /${REPO_FULL_NAME}/build/package/binaries/linux/installer.sh .
cp /binaries/* usr/bin/
cp /${REPO_FULL_NAME}/LICENSE LICENSE.txt

cd ..
TAG_WITHOUT_V=$(echo $TAG | cut -d "v" -f 2)
tar -czvf newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz *



#echo "===> Uploading GitHub asset... "
#GH_ASSET="https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"
#curl "$GITHUB_OAUTH_BASIC" --data-binary @"$filename" -H "Authorization: token $github_api_token" -H "Content-Type: application/octet-stream" $GH_ASSET


# echo "Running command $@"
# exec "$@"