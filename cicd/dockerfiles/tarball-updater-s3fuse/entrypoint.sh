#!/bin/bash
#
#
# Downloads win (zip) and linux (tar.gz) from GH Release assets and uploads them to S3 repo.
#
#
set -e

ARCH_LINUX=( amd64 386 )
ARCH_WINDOWS=( amd64 386 )


[ "${DEBUG:-false}" == 'true' ] && { set -x; S3FS_DEBUG='-d -d'; }

# Defaults
: ${AWS_S3_AUTHFILE:='/root/.s3fs'}
: ${AWS_S3_MOUNTPOINT:='/mnt/repo'}
: ${AWS_S3_URL:='https://s3.amazonaws.com'}
: ${S3FS_ARGS:=''}

# If no command specified, print error
[ "$1" == "" ] && set -- "$@" bash -c 'echo "Error: Please specify a command to run."; exit 128'

# Configuration checks
if [ -z "$AWS_STORAGE_BUCKET_NAME" ]; then
    echo "Error: AWS_STORAGE_BUCKET_NAME is not specified"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Error: AWS_ACCESS_KEY_ID not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_SECRET_ACCESS_KEY not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

# Write auth file if it does not exist
if [ ! -f "${AWS_S3_AUTHFILE}" ]; then
   echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > ${AWS_S3_AUTHFILE}
   chmod 400 ${AWS_S3_AUTHFILE}
fi

mkdir -p ${AWS_S3_MOUNTPOINT}

echo "===> Mounting s3 in local docker with Fuse"
s3fs $S3FS_DEBUG $S3FS_ARGS -o passwd_file=${AWS_S3_AUTHFILE} -o url=${AWS_S3_URL} ${AWS_STORAGE_BUCKET_NAME} ${AWS_S3_MOUNTPOINT}

echo "===> Download Linux packages from GH Release Assets and uploading to S3"
for arch_linux in "${ARCH_LINUX[@]}"; do
  package_name="newrelic-infra_linux_${TAG:1}_${arch_linux}.tar.gz"
  LOCAL_REPO_PATH="${AWS_S3_MOUNTPOINT}${BASE_PATH}/linux/${arch_linux}"

  echo "===> Downloading ${package_name} from GH"
  wget --quiet https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/${package_name}

  echo "===> Uploading ${package_name} to S3 in ${BASE_PATH}/linux/${arch_linux}"
  cp ${package_name} ${LOCAL_REPO_PATH}/
done

echo "===> Download Windows packages from GH Release Assets and uploading to S3"
for arch_windows in "${ARCH_WINDOWS[@]}"; do
  package_name="newrelic-infra_windows_${TAG:1}_${arch_windows}.zip"
  LOCAL_REPO_PATH="${AWS_S3_MOUNTPOINT}${BASE_PATH}/windows/${arch_windows}"

  echo "===> Downloading ${package_name} from GH"
  wget --quiet https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/${package_name}

  echo "===> Uploading ${package_name} to S3 in ${BASE_PATH}/windows/${arch_windows}"
  cp ${package_name} ${LOCAL_REPO_PATH}/
done