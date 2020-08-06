#!/bin/bash
#
# Pipeline bash functions
#
#

set -e

####  DynamoDB lock ####
#
#
# This script implements the locking mechanism functions to not having concurrent jobs
# updating the S3 repos (APT, YUM, ZYPP...). It creates a lock for each repo type in DynamoDB.
#
# AWS_DEFAULT_REGION='us-east-1'
# DYNAMO_TABLENAME='s3-repo-lock'
# LOCK_REPO_TYPE='apt'
# LOCK_TTL=6 # equivalent to 60 sec

function create_dynamo_table {
  # Setup DynamoDB table
  if aws dynamodb describe-table --table-name $DYNAMO_TABLE_NAME --region $AWS_DEFAULT_REGION >/dev/null 2>&1 ; then
    echo "===>Dynamodb lock table already exists"
  else
    aws dynamodb create-table \
            --region $AWS_DEFAULT_REGION \
            --table-name $DYNAMO_TABLE_NAME \
            --attribute-definitions AttributeName=lock-type,AttributeType=S \
            --key-schema AttributeName=lock-type,KeyType=HASH \
            --sse-specification Enabled=true \
            --provisioned-throughput ReadCapacityUnits=2,WriteCapacityUnits=1
    aws dynamodb wait table-exists --table-name $DYNAMO_TABLE_NAME --region $AWS_DEFAULT_REGION
    aws dynamodb put-item \
        --table-name $DYNAMO_TABLE_NAME \
        --item '{"lock-type": {"S": "yum"}, "locked": {"BOOL": false}}'
    aws dynamodb put-item \
        --table-name $DYNAMO_TABLE_NAME \
        --item '{"lock-type": {"S": "apt"}, "locked": {"BOOL": false}}'
    aws dynamodb put-item \
        --table-name $DYNAMO_TABLE_NAME \
        --item '{"lock-type": {"S": "zypp"}, "locked": {"BOOL": false}}'
    aws dynamodb put-item \
        --table-name $DYNAMO_TABLE_NAME \
        --item '{"lock-type": {"S": "win"}, "locked": {"BOOL": false}}'
    aws dynamodb put-item \
        --table-name $DYNAMO_TABLE_NAME \
        --item '{"lock-type": {"S": "tarball"}, "locked": {"BOOL": false}}'
  fi
}

function wait_free_lock {
  echo "===>Wait free lock in a loop until LOCK_TTL"
  while true; do
    locked=$(aws dynamodb get-item \
       --table-name $DYNAMO_TABLE_NAME  \
       --key "{ \"lock-type\": {\"S\": \"${LOCK_REPO_TYPE}\"} }" \
       --projection-expression "locked" \
      | jq -r '.Item.locked.BOOL');
    if [[ $locked == "false" || $counter -ge $LOCK_TTL ]]; then
      break
    fi
    sleep 10
    counter=$((counter+1))
  done
}

function lock {
  echo "===>Locking $LOCK_REPO_TYPE"
  aws dynamodb put-item \
    --table-name $DYNAMO_TABLE_NAME \
    --item "{\"lock-type\": {\"S\": \"${LOCK_REPO_TYPE}\"}, \"locked\": {\"BOOL\": true}}"
}

function release_lock {
  echo "===>Release Lock in $LOCK_REPO_TYPE"
  aws dynamodb put-item \
    --table-name $DYNAMO_TABLE_NAME \
    --item "{\"lock-type\": {\"S\": \"${LOCK_REPO_TYPE}\"}, \"locked\": {\"BOOL\": false}}"
}
