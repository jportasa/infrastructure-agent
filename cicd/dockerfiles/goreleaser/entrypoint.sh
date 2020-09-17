#!/bin/bash

set -e
#
#
# Run goreleaser to create binaries, deb, rpm
#
#
echo "===> Get files from other repos and put them in /other-repos"
echo "===> Adding nri-docker"
mkdir -p /other-repos/nri-docker
curl -SL "https://download.newrelic.com/infrastructure_agent/binaries/linux/${NRI_DOCKER_ARCH}/nri-docker_linux_${NRI_DOCKER_VERSION}_${NRI_DOCKER_ARCH}.tar.gz" | tar xz -C /other-repos/nri-docker
echo "===> Adding nri-flex"
mkdir -p /other-repos/nri-flex
curl -SL "https://github.com/newrelic/nri-flex/releases/download/v${NRI_FLEX_VERSION}/nri-flex_${NRI_FLEX_VERSION}_${NRI_FLEX_OS}_${NRI_FLEX_ARCH}.tar.gz" | tar xz -C /other-repos/nri-flex
echo "===> Adding Fluentbit"
mkdir -p /other-repos/fluent-bit
curl -SL https://${AWS_S3_FQDN}/infrastructure_agent/deps/fluent-bit/linux/nrfb-${FLUENTBIT_VERSION}-linux-amd64.tar.gz | tar xz -C /other-repos/fluent-bit

echo "===> Importing GPG private key from GHA secrets..."
printf %s ${GPG_APT_PRIVATE_KEY} | base64 -d | gpg --batch --import -

echo "===> List GPG keys"
gpg --list-keys

echo "===> Check if there are already .deb release assets in GH"
release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )
download_urls=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets | jq --raw-output '.[].browser_download_url' | grep .deb >/dev/null 2>&1 || echo 'empty')

echo "===> Strip from TAG v character"
TAG=`echo ${TAG:1}`

echo "===> Create .rpmmacros to sign rpm's from Goreleaser"
echo "%_gpg_name ${GPG_APT_MAIL}" >> ~/.rpmmacros
echo "%_signature gpg" >> ~/.rpmmacros
echo "%_gpg_path /root/.gnupg" >> ~/.rpmmacros
echo "%_gpgbin /usr/bin/gpg2" >> ~/.rpmmacros
echo "%__gpg_sign_cmd   %{__gpg} gpg --no-verbose --no-armor --batch --pinentry-mode loopback --passphrase ${GPG_APT_PASSPHRASE} --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}" >> ~/.rpmmacros

echo "===> Importing GPG signature, needed from Goreleaser to sign"
gpg --export -a ${GPG_APT_MAIL} > /tmp/RPM-GPG-KEY-${GPG_APT_MAIL}
rpm --import /tmp/RPM-GPG-KEY-${GPG_APT_MAIL}

goreleaser release --config=.goreleaser.yml --rm-dist --snapshot

##################
#   Sign RPM's   #
##################

cd dist
for rpm_file in $(find -regex ".*\.\(rpm\)");do
  echo "===> Signing $rpm_file"
  rpm --addsign $rpm_file
  echo "===> Sign verification $rpm_file"
  rpm -v --checksig $rpm_file
done

###############################
#  Push to GH Release Assets  #
###############################

if $GITHUB_PUSH_PRERELEASE_ASSETS; then
  for artifact in $(find -regex ".*\.\(msi\|rpm\|deb\|zip\|tar.gz\)");do
    echo "===> Pushing to GH $TAG asset: $artifact"
    hub release edit --attach $artifact v${TAG} --message "v${TAG}"
  done
fi



