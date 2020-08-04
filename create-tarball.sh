#!/bin/bash

cd $1
touch kk.txt
mkdir -p /etc/init_scripts
mkdir -p ./usr/bin/
mv newrelic-infra ./usr/bin/