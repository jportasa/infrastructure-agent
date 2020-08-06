#!/bin/bash

set -e

CODENAMES=( bionic buster jessie precise stretch trusty wheezy xenial )

echo "===> Downloading ${REPO_NAME}_${TAG:1}_amd64.deb from GitHub"
DEB_PACKAGE="${REPO_NAME}_${TAG:1}_amd64.deb"
POOL_PATH="pool/main/n/${REPO_NAME}/${DEB_PACKAGE}"
curl -SL https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/${DEB_PACKAGE} -o ${DEB_PACKAGE}

echo "===> Importing GPG signature and getting KeyId"
printf %s ${GPG_PRIVATE_KEY} | base64 --decode | gpg --batch --import -
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | awk '/sec/{if (length($2) > 0) print $2}' | cut -d "/" -f2)
echo "GPG_KEY_ID = $GPG_KEY_ID"

echo "===> Installing Depot Pyhton script"
git clone $DEPOT_REPO
cd depot; python setup.py install

echo "===> Start Uploading S3 APT repo with Depot script"
cd /

for codename in "${CODENAMES[@]}"; do
   echo "==> Uploading to S3 ${DEB_PACKAGE} to component=main and codename=${codename}"
   depot --storage=${S3_REPO_URL}/${BASE_PATH} \
      --component=main \
      --codename=${codename} \
      --pool-path=${POOL_PATH} \
      --gpg-key ${GPG_KEY_ID} \
      --passphrase ${GPG_PASSPHRASE} \
      /${DEB_PACKAGE} \
      --force
done

