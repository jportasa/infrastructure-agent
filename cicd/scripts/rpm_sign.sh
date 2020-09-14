#!/bin/bash
#
#
# Sign RPM
#
#
set -e
RPM_FILE=$1

echo "%_gpg_name ${GPG_APT_MAIL}" >> ~/.rpmmacros
echo "%_signature gpg" >> ~/.rpmmacros
echo "%_gpg_path /root/.gnupg" >> ~/.rpmmacros
echo "%_gpgbin /usr/bin/gpg2" >> ~/.rpmmacros
echo "%__gpg_sign_cmd   %{__gpg} gpg --no-verbose --no-armor --batch --pinentry-mode loopback --passphrase ${GPG_APT_PASSPHRASE} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}" >> ~/.rpmmacros

gpg --export -a ${GPG_APT_MAIL} > RPM-GPG-KEY-${GPG_APT_MAIL}
rpm --import RPM-GPG-KEY-${GPG_APT_MAIL}

echo "===> Signing $RPM_FILE, call from goreleaser, postinstall"
rpm --addsign $RPM_FILE
echo "===> Sign verification $RPM_FILE,call from goreleaser, postinstall"
rpm -v --checksig $RPM_FILE