#!/bin/bash

set -e
#
#
# Create Tarball for Linux and Windows and push it to GH Release Assets
#
#
TAG_WITHOUT_V=`echo ${TAG:1}`
release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )

######## LINUX section ########
echo "===> Downloading Linux Tarball binaries from GH"
cd /${REPO_FULL_NAME}
mkdir -p binaries/linux && cd binaries/linux
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG_WITHOUT_V}_amd64.tar.gz"
wget $URL -O - | tar -xz

echo "===> Creating Tarball newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz"
cd /${REPO_FULL_NAME}
mkdir -p tarball/linux/newrelic-infra && cd tarball/linux/newrelic-infra
mkdir -p etc/{newrelic-infra/integrations.d,init_scripts/{systemd,sysv,upstart}}
mkdir -p usr/bin
mkdir -p var/{db,log/newrelic-infra,run/newrelic-infra}

cp /${REPO_FULL_NAME}/build/package/binaries/linux/config_defaults.sh .
cp /${REPO_FULL_NAME}/build/package/systemd/newrelic-infra.service etc/init_scripts/systemd/
cp /${REPO_FULL_NAME}/build/package/sysv/deb/newrelic-infra  etc/init_scripts/sysv/
cp /${REPO_FULL_NAME}/build/package/upstart/newrelic-infra  etc/init_scripts/upstart/
cp /${REPO_FULL_NAME}/build/package/binaries/linux/installer.sh .
cp /${REPO_FULL_NAME}/binaries/linux/* usr/bin/
cp /${REPO_FULL_NAME}/LICENSE LICENSE.txt

cd /${REPO_FULL_NAME}/tarball/linux
tar -czvf newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz *

echo "===> Uploading GitHub asset newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz to TAG=$TAG"
filename=newrelic-infra_linux_${TAG_WITHOUT_V}_amd64.tar.gz
ls -la
curl \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/octet-stream" \
     --data-binary @$filename \
     "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"


######## WINDOWS section ########
echo "===> Downloading Windows Tarball binaries from GH"
cd /${REPO_FULL_NAME}
mkdir binaries/windows && cd binaries/windows
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_windows_${TAG_WITHOUT_V}_amd64.zip"
wget $URL -O - | tar -xz

echo "===> Creating Tarball newrelic-infra_windows_${TAG_WITHOUT_V}_amd64.tar.gz"
cd /${REPO_FULL_NAME}
mkdir -p tarball/windows/newrelic-infra && cd tarball/windows/newrelic-infra
mkdir -p 'Program Files/New Relic/newrelic-infra'/{custom-integrations,integrations.d,newrelic-integrations}

cp /${REPO_FULL_NAME}/build/package/binaries/windows/installer.ps1 'Program Files/New Relic/newrelic-infra/'
cp /${REPO_FULL_NAME}/binaries/windows/*.exe 'Program Files/New Relic/newrelic-infra/'
# cp ......   'Program Files/New Relic/newrelic-infra/yamlgen.exe'

cd /${REPO_FULL_NAME}/tarball/windows
zip -r newrelic-infra_windows_${TAG_WITHOUT_V}_amd64.zip .

echo "===> Uploading GitHub asset newrelic-infra_windows_${TAG_WITHOUT_V}_amd64.tar.gz to TAG=$TAG"
filename=newrelic-infra_windows_${TAG_WITHOUT_V}_amd64.zip
curl \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/octet-stream" \
     --data-binary @$filename \
     "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"