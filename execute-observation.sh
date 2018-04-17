#!/bin/bash

# execute setup

BASE_DIR=$(cd "$(dirname "$0")"; pwd)



WORKLOADS="$1"
TYPE="$2"

if [ "$WORKLOADS" == "" ] ; then
	echo "Missing workloads."
	echo "Use one of FishLover,SingleReptileBuyer,SingleCatBuyer,BrowsingUser,AccountManager,CatLover,NewCustomer"
	exit 1
fi

if [ "$TYPE" == "" ] ; then
	echo "No types specified."
	exit 1
fi

echo "--------------------------------------------------------------------"
echo "$TYPE $WORKLOADS"
echo "--------------------------------------------------------------------"

rm -rf $BASE_DIR/analysis/*

if [ -d $BASE_DIR/data/$WORKLOADS ] ; then
	rm -rf $BASE_DIR/data/$WORKLOADS/kieker*
else
	mkdir -p $BASE_DIR/data/$WORKLOADS
fi

# check if no leftovers are running
for I in `docker ps | awk '{ print $1,$2 }' | grep "single-jpetstore" | awk '{ print $1 }'` ; do
	docker stop $I
	docker rm $I
done

killall -9 phantomjs

# configure collector
cat << EOF > collector.config
# common
kieker.monitoring.name=$TYPE
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

# TCP collector
iobserve.service.reader=org.iobserve.service.source.MultipleConnectionTcpCompositeStage
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.port=9876
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.capacity=8192

# dump stage
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$BASE_DIR/data/$WORKLOADS
kieker.monitoring.writer.filesystem.FileWriter.charsetName=UTF-8
kieker.monitoring.writer.filesystem.FileWriter.maxEntriesInFile=25000
kieker.monitoring.writer.filesystem.FileWriter.maxLogSize=-1
kieker.monitoring.writer.filesystem.FileWriter.maxLogFiles=-1
kieker.monitoring.writer.filesystem.FileWriter.mapFileHandler=kieker.monitoring.writer.filesystem.TextMapFileHandler
kieker.monitoring.writer.filesystem.TextMapFileHandler.flush=true
kieker.monitoring.writer.filesystem.TextMapFileHandler.compression=kieker.monitoring.writer.filesystem.compression.NoneCompressionFilter
kieker.monitoring.writer.filesystem.FileWriter.logFilePoolHandler=kieker.monitoring.writer.filesystem.RotatingLogFilePoolHandler
kieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.TextLogStreamHandler
kieker.monitoring.writer.filesystem.FileWriter.flush=true
kieker.monitoring.writer.filesystem.FileWriter.bufferSize=8192
EOF

echo ">>>>>>>>>>> start collector"

$COLLECTOR -c collector.config &
COLLECTOR_PID=$!

sleep 10

# jpetstore

echo ">>>>>>>>>>> start petstore"

docker run single-jpetstore >& docker.log &

while ! curl -sSf $SERVICE_URL ; do
	sleep 1
done

# workload
#$WORKLOADS/workload.sh -u $SERVICE_URL -i 20 -s $BASE/screenshots -p $PHANTOM_JS

echo ">>>>>>>>>>> start workload"

$WORKLOAD_RUNNER -phantomjs "${PHANTOM_JS}" -workloads "${WORKLOADS}" -fuzzy -runs 10

sleep 10

echo "<<<<<<<<<<< term container"

for I in `docker ps | awk '{ print $1,$2 }' | grep "single-jpetstore" | awk '{ print $1 }'` ; do
	docker stop $I
	docker rm $I
done

killall -9 phantomjs
kill -TERM ${COLLECTOR_PID}
rm collector.config

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"

$BASE_DIR/execute-session-reconstruction.sh $TYPE

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

# end

