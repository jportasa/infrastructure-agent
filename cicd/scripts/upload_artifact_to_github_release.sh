#!/bin/bash
#
#
# Upload artifact: path/filename to GH Release asset
#
#
set -e

path=$1
filename=$2

cd ${path}
release_id=$(curl --header "authorization: Bearer $GITHUB_TOKEN" --url https://api.github.com/repos/${REPO_FULL_NAME}/releases/tags/${TAG} | jq --raw-output '.id' )
curl -s \
     -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Content-Type: application/octet-stream" \
     --data-binary @$filename \
     "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"