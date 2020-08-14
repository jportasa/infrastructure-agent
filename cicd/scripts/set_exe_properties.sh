#!/bin/bash
#
#
# Create the metadata for the exe file, called by .goreleser as a hook in the build section
#
#
VERSION=$1

go generate goversioninfo \
  -file-version="$VERSION" \
  -product-name="New Relic Infrastructure Agent" \
  -copyright="(c) 2019 New Relic Inc."