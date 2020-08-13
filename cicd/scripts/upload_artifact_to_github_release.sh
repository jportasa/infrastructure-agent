set -e
#
#
# Upload artifact: path/filename to GH Release asset
#
#
path=$1
filename=$2

cd ${path}
curl -s \
     -H "Authorization: token ${GITHUB_TOKEN}" \
     -H "Content-Type: application/octet-stream" \
     --data-binary @$filename \
     "https://uploads.github.com/repos/${REPO_FULL_NAME}/releases/${release_id}/assets?name=$(basename $filename)"