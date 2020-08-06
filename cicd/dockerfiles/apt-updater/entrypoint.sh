#!/bin/bash

set -e

CODENAMES=( bionic buster jessie precise stretch trusty wheezy xenial )
BOOT=( systemd upstart sysv )

echo "===> Importing GPG signature and getting KeyId"
printf %s ${GPG_APT_PRIVATE_KEY} | base64 --decode | gpg --batch --import -
GPG_APT_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | awk '/sec/{if (length($2) > 0) print $2}' | cut -d "/" -f2)
echo "GPG_APT_KEY_ID = $GPG_APT_KEY_ID"

echo "===> Installing Depot Pyhton script"
git clone $DEPOT_REPO
cd depot; python setup.py install

echo "===> Downloading deb packages from GH"
mkdir -p /artifacts; cd /artifacts
for boot in "${BOOT[@]}"; do
  echo "===> Downloading newrelic_infra_${boot}_${TAG:1}_amd64.deb from GH"
  DEB_PACKAGE="newrelic-infra_${boot}_${TAG:1}_amd64.deb"
  POOL_PATH="pool/main/n/newrelic-infra/${DEB_PACKAGE}"
  curl -SL https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/${DEB_PACKAGE} -o ${DEB_PACKAGE}
done

pwd
ls -la


echo "===> Start Uploading S3 APT repo with Depot script"
for codename in "${CODENAMES[@]}"; do
  for boot in "${BOOT[@]}"; do
   echo "==> Uploading to S3 ${DEB_PACKAGE} to component=main and codename=${codename}"
   depot --storage=${S3_REPO_URL}/${BASE_PATH} \
      --component=main \
      --codename=${codename} \
      --pool-path=${POOL_PATH} \
      --gpg-key ${GPG_APT_KEY_ID} \
      --passphrase ${GPG_APT_PASSPHRASE} \
      /artifacts/newrelic-infra_${boot}_${TAG:1}_amd64.deb \
      --force
  done
done


