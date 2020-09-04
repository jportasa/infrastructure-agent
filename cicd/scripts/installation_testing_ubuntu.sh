#!/bin/bash
#
#
# Over VM Ubuntu 18.04 installs production release and tries to install the prerelease.
#
#
set -e

echo "===> Production release installation over Ubuntu 18.04"
curl -s ${AWS_S3_FQDN}/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -
printf "deb [arch=amd64] ${AWS_S3_FQDN}/infrastructure_agent/linux/apt bionic main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt-get update
sudo apt-get install newrelic-infra -y

echo "===> Prerelease installation over Ubuntu 18.04"
curl -s ${AWS_S3_FQDN}/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -
printf "deb [arch=amd64] ${AWS_S3_FQDN}/infrastructure_agent/linux/apt bionic main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt-get update
sudo apt-get install newrelic-infra -y