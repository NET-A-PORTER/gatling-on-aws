#!/usr/bin/env bash
set -o errexit
set -o nounset

GATLING_URL=https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/2.1.4/gatling-charts-highcharts-bundle-2.1.4-bundle.zip

export GATLING_HOME=target/gatling-charts-highcharts-bundle-2.1.4

if [ ! -d "$GATLING_HOME" ]; then
    mkdir -p target
    echo "Downloading Gatling"

    curl -o target/gatling.zip $GATLING_URL

    unzip target/gatling.zip -d target

    rm -r $GATLING_HOME/user-files

    ln -s ../.. $GATLING_HOME/user-files

    cat <<EOF >> $GATLING_HOME/conf/gatling.conf
gatling.charting.indicators {
  lowerBound = 40
  higherBound = 250
}
EOF

fi

export GATLING="$GATLING_HOME/bin/gatling.sh"
