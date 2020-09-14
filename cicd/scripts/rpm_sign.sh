#!/bin/bash
#
#
# Sign RPM's with GPG. Is a workaround waiting for goreleaser launch Sign deb/rpm, it is WIP PR.
#
#
set -e

echo "%_gpg_name ${GPG_APT_MAIL}" >> ~/.rpmmacros
echo "%_signature gpg" >> ~/.rpmmacros
echo "%_gpg_path /root/.gnupg" >> ~/.rpmmacros
echo "%_gpgbin /usr/bin/gpg2" >> ~/.rpmmacros
echo "%__gpg_sign_cmd   %{__gpg} gpg --no-verbose --no-armor --batch --pinentry-mode loopback --passphrase ${GPG_APT_PASSPHRASE} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}" >> ~/.rpmmacros

echo "===> Importing GPG signature"
gpg --export -a ${GPG_APT_MAIL} > RPM-GPG-KEY-${GPG_APT_MAIL}
rpm --import RPM-GPG-KEY-${GPG_APT_MAIL}

echo "===> Signing ./dist/$RPM_FILE, called from goreleaser, postinstall"
rpm --addsign ./dist/*.rpm
echo "===> Sign verification $RPM_FILE"
rpm -v --checksig ./dist/*.rpm





