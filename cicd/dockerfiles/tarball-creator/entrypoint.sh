#!/bin/bash

set -e
#
#
# Create Tarballs for Linux and Windows and push them to GH Release Assets
#
#
ARCH-LINUX=( x86_64 386 arm arm64 )
ARCH-WIN=( x86_64 386 )

release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )

######## LINUX section ########
for arch-linux in "${ARCH-LINUX[@]}"; do
  echo "===> Downloading newrelic-infra_binaries_linux_${TAG:1}_${arch-linux}.tar.gz from GH"
  cd /${REPO_FULL_NAME}
  mkdir -p binaries/linux/${arch-linux}
  URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG:1}_${arch-linux}.tar.gz"
  curl -SL $URL | tar xz -C binaries/linux/${arch-linux}

  echo "===> Creating Tarball newrelic-infra_linux_${TAG:1}_${arch-linux}.tar.gz"
  cd /${REPO_FULL_NAME}
  mkdir -p tarball/linux/${arch-linux}/newrelic-infra && cd tarball/linux/${arch-linux}/newrelic-infra
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

  cd /${REPO_FULL_NAME}/tarball/linux/${arch-linux}
  tar -czvf newrelic-infra_linux_${TAG:1}_${arch-linux}.tar.gz *

  echo "===> Uploading newrelic-infra_linux_${TAG:1}_${arch-linux}.tar.gz to GH"
  filename=newrelic-infra_linux_${TAG:1}_${arch-linux}.tar.gz
  ls -la
  curl -s \
       -H "Authorization: token $GITHUB_TOKEN" \
       -H "Content-Type: application/octet-stream" \
       --data-binary @$filename \
       "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"
done

######## WINDOWS section ########
for arch-win in "${ARCH-WIN[@]}"; do
  echo "===> Downloading newrelic-infra_binaries_windows_${TAG:1}_${arch-win}.zip from GH"
  cd /${REPO_FULL_NAME}
  mkdir -p binaries/windows/${arch-win}
  URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_windows_${TAG:1}_${arch-win}.zip"
  curl -SL $URL | bsdtar -xf - -C binaries/windows/${arch-win}

  echo "===> Creating Tarball newrelic-infra_windows_${TAG:1}_${arch-win}.zip"
  cd /${REPO_FULL_NAME}
  mkdir -p tarball/windows/${arch-win}/newrelic-infra && cd tarball/windows/${arch-win}/newrelic-infra
  mkdir -p 'Program Files/New Relic/newrelic-infra'/{custom-integrations,integrations.d,newrelic-integrations}

  cp /${REPO_FULL_NAME}/build/package/binaries/windows/installer.ps1 'Program Files/New Relic/newrelic-infra/'
  cp /${REPO_FULL_NAME}/binaries/windows/*.exe 'Program Files/New Relic/newrelic-infra/'
  # cp ......   'Program Files/New Relic/newrelic-infra/yamlgen.exe'

  cd /${REPO_FULL_NAME}/tarball/windows/${arch-win}
  zip -r newrelic-infra_windows_${TAG:1}_${arch-win}.zip .

  echo "===> Uploading newrelic-infra_windows_${TAG:1}_${arch-win}.zip to GH"
  filename=newrelic-infra_windows_${TAG:1}_${arch-win}.zip
  curl -s \
       -H "Authorization: token $GITHUB_TOKEN" \
       -H "Content-Type: application/octet-stream" \
       --data-binary @$filename \
       "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"
done