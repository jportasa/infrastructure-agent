#!/bin/bash
#
#
# Over VM Ubuntu 18.04 installs production release and tries to install the prerelease.
#
#
set -e

# AWS_S3_FQDN='nr-clone.s3.amazonaws.com'

sudo apt-get update
sudo apt install gnupg curl -y
curl -s https://${AWS_S3_FQDN}/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -

echo "===> Production release installation over Ubuntu 18.04"
printf "deb [arch=amd64] https://${AWS_S3_FQDN}/infrastructure_agent/linux/apt bionic main\n" |  sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt-get update
sudo apt-get install newrelic-infra -y

echo "===> Prerelease installation over Ubuntu 18.04"
printf "deb [arch=amd64] https://${AWS_S3_FQDN}/infrastructure_agent/test/linux/apt bionic main\n" |  sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
sudo apt-get update
sudo apt-get install newrelic-infra -y