#!/usr/bin/env bash
set -o errexit
set -o nounset


PROPS="-Xms3g -Xmx3g -Djava.security.manager -Djava.security.policy=security.policy -Djava.security.properties=security.properties"
ARGS=""
RUN_ID=""
END_TIME=""
SIMULATION=""
INTERACTIVE="yes"
INSTANCE_COUNT=1
S3_BUCKET=""


usage() {
cat << END_OF_HELP
Usage:

  $ ./run.sh -e END_TIME -r RUN_ID -s ReplaySimulation [-n] [-u 10] [-b http://localhost:8080] [-h]

Parameters:

 -u USERS          -- Number of users
 -b BASE_URL       -- e.g. localhost:8080
 -e END_TIME       -- End time in seconds since 1970-01-01 00:00:00.00 UTC
 -i INSTANCES      -- Number of instances, including this instance, running this test
 -n                -- Do not generate a report
 -h                -- This help
 -s SIMULATION     -- e.g. ReplaySimulation
 -r RUN_ID         -- e.g. run-id - must be a valid S3 object name
 -c S3_BUCKET
END_OF_HELP
  exit $1
}
while getopts "nhu:b:e:s:r:i:c:" opt
do
    case $opt in
        h) usage 0 ;;
        u) PROPS="-Dtest.users=$OPTARG $PROPS" ;;
        b) PROPS="-Dtest.baseUrl=$OPTARG $PROPS" ;;
        e) END_TIME=$OPTARG ;;
        n) INTERACTIVE="no"
           ARGS="-nr $ARGS" ;;
        s) SIMULATION="$OPTARG" ;;
        r) RUN_ID="$OPTARG"
           ARGS="-rd ${OPTARG} ${ARGS}" ;;
        i) INSTANCE_COUNT=${OPTARG} ;;
        c) S3_BUCKET=${OPTARG} ;;
        :) echo "$opt requires an argument"; usage 4 ;;
    esac
done

if [ "x$RUN_ID" = x ]; then
  echo "RUN_ID must be supplied with the -r parameter and be a valid S3 object name"
  usage 4
fi

if [ "x$END_TIME" = x ]; then
  echo "END_TIME must be supplied with the -e parameter"
  usage 4
fi

if [ "x$SIMULATION" = x ]; then
    echo "SIMULATION must be supplied with the -s parameter"
    usage 4
fi

if [ "x$S3_BUCKET" = x ]; then
    echo "S3_BUCKET must be supplied with the -c parameter"
    usage 4
fi

NOW_TIME=$(date +%s)
if [ $NOW_TIME -gt $END_TIME ]; then exit 0; fi

OUTPUT_NAME=${SIMULATION}-${NOW_TIME}
ARGS="-on ${OUTPUT_NAME} ${ARGS}"

REMAINING_DURATION=$((END_TIME - NOW_TIME))
PROPS="-Dtest.instanceCount=${INSTANCE_COUNT} -Dtest.duration=$REMAINING_DURATION $PROPS"
export JAVA_OPTS=$PROPS

source gatling.sh

LOG="${GATLING_HOME}/results/${OUTPUT_NAME}-*/simulation.log"

METADATA=/opt/aws/bin/ec2-metadata
if [ -x $METADATA ] ; then
    INSTANCE=$($METADATA -i | cut -d' ' -f2)
else
    INSTANCE=`hostname -s`
fi

S3LOG="s3://$S3_BUCKET/reports/${RUN_ID}/${INSTANCE}.log"

if [ $INTERACTIVE = "yes" ] ; then
    $GATLING -s $SIMULATION $ARGS
else
    $GATLING -s $SIMULATION $ARGS > /tmp/gatling2.log 2>&1 &

    SCENARIO_PID=$!

    echo "Gatling is silent and detached as PID ${SCENARIO_PID}"

    set +o errexit

    while [ $(date +%s) -lt $END_TIME ] ; do
        sleep 5
        aws s3 cp ${LOG} ${S3LOG}
    done

    wait $SCENARIO_PID

    aws s3 cp ${LOG} ${S3LOG}
fi
