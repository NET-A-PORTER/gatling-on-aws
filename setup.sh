#!/usr/bin/env bash
set -o errexit
set -o nounset

INSTANCES=1
USERS=10
DURATION=50
SIMULATION=ReplaySimulation
URL=""
RUN_ID=
REGION=eu-west-1
S3_BUCKET=""

usage() {
    exit_code=$1
    cat <<EOF
Usage:

  $ setup.sh -r RUN_ID [-b $URL] [-i $INSTANCES] [-u $USERS] [-d $DURATION] [-g $REGION] [-h]

Parameters:

 -r RUN_ID         -- The "name" of this run. Used as an S3 bucket name.
 -b URL            -- The URL to hit
 -i INSTANCES      -- How many VMs to launch (default: $INSTANCES)
 -u USERS          -- Number of users (default: $USERS)
 -d DURATION       -- Duration in minutes (default: $DURATION)
 -s SIMULATION     -- Name of simulation to run (default: $SIMULATION)
 -g REGION         -- Region of the stack (default: $REGION)
 -h                -- This help
 -c S3_BUCKET      -- The S3 Bucket where the simulations live

Simulations:

EOF
grep ^class simulations/* | cut -d' ' -f2 | sed -e 's/^/ * /'
    exit $exit_code
}

while getopts "r:b:u:d:i:g:hs:c:" opt ; do
    case $opt in
        h) usage 0 ;;
        i) INSTANCES=$OPTARG ;;
        u) USERS=$OPTARG ;;
        d) DURATION=$OPTARG ;;
        s) SIMULATION=$OPTARG ;;
        r) RUN_ID=$OPTARG ;;
        b) URL=$OPTARG ;;
        g) REGION=$OPTARG ;;
        c) S3_BUCKET=$OPTARG ;;
    esac
done

if [ "x$RUN_ID" = x ]; then
  echo "Err: RUN_ID must be supplied with the -r parameter and be a valid S3 object name"
  usage 4
fi

if [ "$REGION" != "ap-northeast-1" ] && [ "$REGION" != "ap-southeast-1" ] && [ "$REGION" != "ap-southeast-2" ] && [ "$REGION" != "eu-central-1" ] && [ "$REGION" != "eu-west-1" ] && [ "$REGION" != "sa-east-1" ] && [ "$REGION" != "us-east-1" ] && [ "$REGION" != "us-west-1" ]  && [ "$REGION" != "us-west-2" ]; then
     echo -e "\nErr: The REGION must be one of: ap-northeast-1, ap-southeast-1, ap-southeast-2, eu-central-1, eu-west-1, sa-east-1, us-east-1, us-west-1, us-west-2 ."
     usage 4
fi

NOW_TIME=$(date +%s)
END_TIME=$(($NOW_TIME + 60 * $DURATION))

aws --region $REGION cloudformation create-stack \
    --stack-name "load-test-$RUN_ID" \
    --capabilities CAPABILITY_IAM \
    --template-body file://load-test-vpc.json \
    --parameters ParameterKey=RunId,ParameterValue=$RUN_ID \
    ParameterKey=Instances,ParameterValue=$INSTANCES \
    ParameterKey=Users,ParameterValue=$USERS \
    ParameterKey=EndTime,ParameterValue=$END_TIME \
    ParameterKey=LoadMultipler,ParameterValue=$LOAD_MULTIPLER \
    ParameterKey=Simulation,ParameterValue=$SIMULATION \
    ParameterKey=Url,ParameterValue=${URL%%/} \
    ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET \
