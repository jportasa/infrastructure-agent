#!/bin/bash
#
#
# Sign RPM's with GPG. Is a workaround waiting for goreleaser launch Sign deb/rpm, it is WIP PR.
#
#
set -e
SIGNATURE=$1
ARTIFACT=$2

if [ ${ARTIFACT: -4} == ".rpm" ]; then
  echo "===> Signing $ARTIFACT, called from goreleaser, postinstall"
  rpm --addsign $ARTIFACT
  echo "===> Sign verification $RPM_FILE"
  rpm -v --checksig $ARTIFACT
fi

echo "===> Creating signature checksum"
gpg2 --batch -u ${GPG_APT_MAIL} --passphrase ${GPG_APT_PASSPHRASE} --pinentry-mode loopback --output ${SIGNATURE} --detach-sign ${ARTIFACT}




