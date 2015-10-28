#!/usr/bin/env bash
set -o errexit
set -o nounset

S3_BUCKET=$1
RUN_ID=$2

source gatling.sh
LOG_DIR=$GATLING_HOME/results/$RUN_ID

echo $LOG_DIR
echo

mkdir -p $LOG_DIR
aws s3 sync s3://$S3_BUCKET/reports/$RUN_ID $LOG_DIR

echo $GATLING - $RUN_ID

$GATLING -ro $RUN_ID


open $GATLING_HOME/results/$RUN_ID/index.html
