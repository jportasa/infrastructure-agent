#!/bin/bash
#
#
# Sign RPM's with GPG
#
#
set -e

RPM_FILE=$1

if [ ${RPM_FILE: -4} == ".rpm" ]; then
  echo "%_gpg_name ${GPG_APT_MAIL}" >> ~/.rpmmacros
  echo "%_signature gpg" >> ~/.rpmmacros
  echo "%_gpg_path /root/.gnupg" >> ~/.rpmmacros
  echo "%_gpgbin /usr/bin/gpg2" >> ~/.rpmmacros
  echo "%__gpg_sign_cmd   %{__gpg} gpg --no-verbose --no-armor --batch --pinentry-mode loopback --passphrase ${GPG_APT_PASSPHRASE} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}" >> ~/.rpmmacros

  echo "===> Importing GPG signature"
  gpg --export -a ${GPG_APT_MAIL} > RPM-GPG-KEY-${GPG_APT_MAIL}
  rpm --import RPM-GPG-KEY-${GPG_APT_MAIL}

  echo "===> Signing $RPM_FILE, called from goreleaser, postinstall"
  rpm --addsign $RPM_FILE
  echo "===> Sign verification $RPM_FILE"
  rpm -v --checksig $RPM_FILE
  rm ~/.rpmmacros
else
  echo "==> Skip to next artifact..."
fi