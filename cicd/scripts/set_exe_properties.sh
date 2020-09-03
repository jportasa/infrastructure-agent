#!/bin/bash
#
#
# Create the metadata for the exe file, called by .goreleser as a hook in the build section
#
#
VERSION=$1

if [ -n "$1" ]; then
  echo "===> Release Version is $VERSION"
else
  echo "===> Release Version not specified will be v0.0.0"
  VERSION='v0.0.0'
fi


AgentMajorVersion=$(echo ${VERSION:1} | cut -d "." -f 1)
AgentMinorVersion=$(echo ${VERSION:1} | cut -d "." -f 2)
AgentPatchVersion=$(echo ${VERSION:1} | cut -d "." -f 3)
AgentBuildVersion='0'

sed \
  -e "s/{AgentMajorVersion}/$AgentMajorVersion/g" \
  -e "s/{AgentMinorVersion}/$AgentMinorVersion/g" \
  -e "s/{AgentPatchVersion}/$AgentPatchVersion/g" \
  -e "s/{AgentBuildVersion}/$AgentBuildVersion/g" cmd/newrelic-infra/versioninfo.json.template > cmd/newrelic-infra/versioninfo.json
echo "===> Show json"
cat cmd/newrelic-infra/versioninfo.json
echo "===> Adding metadata to exe with Goversioninfo"
export PATH="$PATH:/go/bin"
echo "===> go get goversioninfo"
go get github.com/josephspurrier/goversioninfo/cmd/goversioninfo
echo "===> go generate goversioninfo"
go generate github.com/newrelic/infrastructure-agent/cmd/newrelic-infra/

