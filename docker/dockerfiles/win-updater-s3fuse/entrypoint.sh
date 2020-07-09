#!/bin/bash

set -e
#
#
# Mount S3 with S3Fuse
#
#
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
#
#
# Uploading TARBALLS's to S3 repo
#
#
echo "===> Download from GH release assets and uploading artifacts to S3 repo"
function github_release_assets_download_upload_s3 (){
# Requires wget, jq
   REPO_FULL_NAME=$1
   TAG=$2
   FILE_EXTENSION=$3
   BASE_DIR=$4
   GITHUB_TOKEN=$5
   release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id')
   echo "===>Release Id of $TAG is $release_id"
   download_urls=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets | jq --raw-output '.[].browser_download_url' | grep $FILE_EXTENSION$ )
   for download_url in $download_urls; do
     wget --quiet $download_url
     arch=$(echo $download_url | cut -d "_" -f 3 | cut -d "." -f1)
     package_name=$( echo $download_url | cut -d "/" -f 9 )
     LOCAL_REPO_PATH="${AWS_S3_MOUNTPOINT}${BASE_DIR}"
     [ -d ${LOCAL_REPO_PATH} ] || mkdir -p ${LOCAL_REPO_PATH}
     echo "===>Uploading $package_name to S3 $BASE_DIR"
     cp ${package_name} ${LOCAL_REPO_PATH}
   done
}

github_release_assets_download_upload_s3 $REPO_FULL_NAME $TAG 'msi' "${BASE_PATH}/${REPO_NAME}" $GITHUB_TOKEN

# echo "Running command $@"
# exec "$@"
