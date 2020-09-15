#!/bin/bash
set -e
#
#
# Create infrastructure-agent docker image and push it to Registry
#
#
echo "===> Init docker vars fefore build image"
export NS=${DOCKERHUB_NAMESPACE}
if [ $PIPELINE_ACTION == 'prereleased' ]; then
  export AGENT_BUILD_NUMBER=${TAG:1}-rc
fi
if [ $PIPELINE_ACTION == 'released' ]; then
  export AGENT_BUILD_NUMBER=${TAG:1}
fi

######################
#     BUILD IMAGE    #
######################
echo "===> Downloading newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz from GH"
URL="https://github.com/${REPO_FULL_NAME}/releases/download/${TAG}/newrelic-infra_binaries_linux_${TAG:1}_amd64.tar.gz"
mkdir -p /${REPO_FULL_NAME}/target/bin/linux_amd64
curl -SL $URL | tar xz -C /${REPO_FULL_NAME}/target/bin/linux_amd64

mkdir -p /${REPO_FULL_NAME}/build/container/workspace
cp -r /${REPO_FULL_NAME}/build/container/assets /${REPO_FULL_NAME}/build/container/workspace
echo 0.0 > /${REPO_FULL_NAME}/build/container/workspace/VERSION
mkdir -p /${REPO_FULL_NAME}/build/container/workspace/ohis

echo "===> Embedding nri-docker ${NRI_DOCKER_VERSION} in docker image"
rm -rf /${REPO_FULL_NAME}/build/container/workspace/target/nridocker/
mkdir -p /${REPO_FULL_NAME}/build/container/workspace/target/nridocker/
if curl --output /dev/null --silent --head --fail "https://download.newrelic.com/infrastructure_agent/binaries/linux/${NRI_DOCKER_ARCH}/nri-docker_linux_${NRI_DOCKER_VERSION}_${NRI_DOCKER_ARCH}.tar.gz"; then
    curl -L --silent "https://download.newrelic.com/infrastructure_agent/binaries/linux/${NRI_DOCKER_ARCH}/nri-docker_linux_${NRI_DOCKER_VERSION}_${NRI_DOCKER_ARCH}.tar.gz" | tar xvz --no-same-owner -C /${REPO_FULL_NAME}/build/container/workspace/target/nridocker/
else
    echo "nri-docker version ${NRI_DOCKER_VERSION} URL does not exist: https://download.newrelic.com/infrastructure_agent/binaries/linux/${NRI_DOCKER_ARCH}/nri-docker_linux_${NRI_DOCKER_VERSION}_${NRI_DOCKER_ARCH}.tar.gz"
    exit 1
fi
echo "===> Embedding nri-flex ${NRI_FLEX_VERSION} in docker image"
rm -rf /${REPO_FULL_NAME}/build/container/workspace/target/nriflex/
mkdir -p /${REPO_FULL_NAME}/build/container/workspace/target/nriflex/
if curl --output /dev/null --silent --head --fail "https://github.com/newrelic/nri-flex/releases/download/v${NRI_FLEX_VERSION}/nri-flex_${NRI_FLEX_VERSION}_Linux_${NRI_FLEX_ARCH}.tar.gz"; then
    curl -L --silent "https://github.com/newrelic/nri-flex/releases/download/v${NRI_FLEX_VERSION}/nri-flex_${NRI_FLEX_VERSION}_Linux_${NRI_FLEX_ARCH}.tar.gz" | tar xvz --no-same-owner -C /${REPO_FULL_NAME}/build/container/workspace/target/nriflex/
else
    echo "nri-flex version ${NRI_FLEX_VERSION} URL does not exist: https://github.com/newrelic/nri-flex/releases/download/v${NRI_FLEX_VERSION}/nri-flex_${NRI_FLEX_VERSION}_Linux_${NRI_FLEX_ARCH}.tar.gz"
    exit 1
fi

mkdir -p /${REPO_FULL_NAME}/build/container/workspace/ohis/var/db/newrelic-infra/newrelic-integrations/bin
cp /${REPO_FULL_NAME}/build/container/workspace/target/nriflex/nri-flex /${REPO_FULL_NAME}/build/container/workspace/ohis/var/db/newrelic-infra/newrelic-integrations/bin/
cp -r /${REPO_FULL_NAME}/build/container/workspace/target/nridocker/* /${REPO_FULL_NAME}/build/container/workspace/ohis
cp /${REPO_FULL_NAME}/build/container/../../target/bin/linux_amd64/* /${REPO_FULL_NAME}/build/container/workspace/

echo "===> Docker build"
docker build --no-cache --pull -t newrelic/infrastructure:0.0 -t newrelic/infrastructure:latest \
  --build-arg image_version=0.0 \
  --build-arg agent_version=0.0 \
  --build-arg version_file=VERSION \
  --build-arg agent_bin=newrelic-infra \
  --build-arg nri_pkg_dir=ohis \
  --build-arg nri_docker_version=${NRI_DOCKER_VERSION} \
  --build-arg nri_flex_version=${NRI_FLEX_VERSION} \
  --target base -f /${REPO_FULL_NAME}/build/container/Dockerfile \
  workspace

######################
#  PUSH TO DOCKERHUB #
######################

docker login --username ${DOCKERHUB_USERNAME} --password ${DOCKERHUB_PASSWORD}
if [ $PIPELINE_ACTION == 'prereleased' ]; then
  echo "===> Push ${DOCKERHUB_NAMESPACE}/infrastructure:${TAG:1}-rc to dockerhub registry"
  docker push ${DOCKERHUB_NAMESPACE}/infrastructure:${TAG:1}-rc
fi
if [ $PIPELINE_ACTION == 'released' ]; then
  echo "===> Push release image to dockerhub registry"
  docker push ${DOCKERHUB_NAMESPACE}/infrastructure:latest
  docker push ${DOCKERHUB_NAMESPACE}/infrastructure:${TAG:1}
fi