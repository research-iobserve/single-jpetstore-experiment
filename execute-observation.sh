#!/bin/bash

# execute setup

BASE=$(cd "$(dirname "$0")"; pwd)/

WORKLOADS=$BASE/../../workloads/jpetstore-selenium-workloads/
KIEKER=$BASE/../kieker-1.12/

PHANTOM_JS="$HOME/node_modules/phantomjs/bin/phantomjs"
SERVICE_URL="http://172.17.0.2:8080/jpetstore"

rm -rf $BASE/data/kieker-*
rm -rf $BASE/analysis/*

# collector

$BASE/../collector-0.0.2-SNAPSHOT/bin/collector -d $BASE/data -p 9876 &

sleep 10

# jpetstore

docker run single-jpetstore >& docker.log &

while ! curl -sSf $SERVICE_URL ; do
	sleep 1
done

# workload
$WORKLOADS/workload.sh -u $SERVICE_URL -i 20 -s $BASE/screenshots -p $PHANTOM_JS

for I in `docker ps | grep "single-jpetstore" | awk '{ print $1 }'` ; do
	docker kill $I
	docker rm $I
done


# end

