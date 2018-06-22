#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

. $BASE_DIR/config
. $BASE_DIR/common-functions.sh

###################
# functions

# stop petstore
function stop-jpetstore() {
	information "Terminate running single-jpetstores ..."

	for I in `docker ps | awk '{ print $1,$2 }' | grep "single-jpetstore" | awk '{ print $1 }'` ; do
		docker stop $I
		docker rm $I
	done

	information "done"
}


######################
# parameter evaluation

export WORKLOAD_CONFIGURATION=`basename "$1" | sed 's/\.yaml$//g'`
export WORKLOAD="$1"
export EXPERIMENT_ID="$2"
export COLLECTOR_OUTPUT_DIR="$DATA_DIR/$WORKLOAD_CONFIGURATION"

if [ "$WORKLOAD_CONFIGURATION" == "" ] ; then
	warning "Missing workloads. Running in interactive mode."
	information "Use one of FishLover,SingleReptileBuyer,SingleCatBuyer,BrowsingUser,AccountManager,CatLover,NewCustomer"
	export WORKLOAD_CONFIGURATION="INTERACTIVE"
	export EXPERIMENT_ID="default"
else
	if [ "${EXPERIMENT_ID}" == "" ] ; then
		error "Missing experiment id."
		exit 1
	fi
fi

##
# are all tools available

checkExecutable collector $COLLECTOR
checkExecutable workload-runner $WORKLOAD_RUNNER
checkExecutable phantomjs $PHANTOM_JS

####################
# main script

information "--------------------------------------------------------------------"
information "$EXPERIMENT_ID $WORKLOAD_CONFIGURATION"
information "--------------------------------------------------------------------"

##
# cleanup

information "Cleanup directories"

if [ -d "$COLLECTOR_OUTPUT_DIR" ] ; then
	rm -rf "$COLLECTOR_OUTPUT_DIR/"kieker*
else
	mkdir -p "$COLLECTOR_OUTPUT_DIR"
fi

stop-jpetstore

information "Cleanup phantomjs"
killall -9 phantomjs

information "Cleanup collector..."

for I in `ps auxw | grep collector | grep java | awk '{ print $2 }'` ; do
	information "stopping $I"
	kill -TERM $I
	sleep 2
	kill -9 $I
done

information "done"
echo ""

##################
# start experiment

information "Deploying experiment..."

##
# collector

information "Start collector"

# configure collector
cat << EOF > collector.config
# common
kieker.monitoring.name=${EXPERIMENT_ID}
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

# TCP collector
iobserve.service.reader=org.iobserve.service.source.MultipleConnectionTcpCompositeStage
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.port=9876
org.iobserve.service.source.MultipleConnectionTcpCompositeStage.capacity=8192

# dump stage
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$COLLECTOR_OUTPUT_DIR
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
kieker.monitoring.writer.filesystem.FileWriter.bufferSize=81920
EOF

export COLLECTOR_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg

$COLLECTOR -c collector.config &
COLLECTOR_PID=$!

sleep 10

##
# jpetstore

information "Start jpetstore"

docker run -e LOGGER="${LOGGER}"  --name 'single-service' -d single-jpetstore

# get IP address of the container

ID=`docker ps | grep 'single-service' | awk '{ print $1 }'`
SERVICE=`docker inspect $ID | grep '"IPAddress' | awk '{ print $2 }' | tail -1 | sed 's/^"\(.*\)",/\1/g'`

SERVICE_URL="http://$SERVICE:8080/jpetstore"

# wait for service coming up

information "Service URL is ${SERVICE_URL}"
information "Connection fails are expected until the service is available."

while ! curl -sSf ${SERVICE_URL} ; do
	sleep 1
done

information "Service ready\n"

##
# workload

if [ "${WORKLOAD_CONFIGURATION}" == "INTERACTIVE" ] ; then
	warning "Interactive mode"
	information "access JPetStore via ${SERVICE_URL}"
	information "press return to stop JPetStore execution"
	read
else
	information "Start workload"

	export SELENIUM_EXPERIMENT_WORKLOADS_OPTS=-Dlog4j.configuration=file:///$BASE_DIR/log4j.cfg
	$WORKLOAD_RUNNER -c $WORKLOAD -u "$SERVICE_URL" -d "$PHANTOM_JS"

	sleep 10
fi

####
# end of experiment

information "Undeploying experiment."

# stop and remove jpetstore
stop-jpetstore

# get rid of phantomjs if it has not correctly terminated with the workload driver
killall -9 phantomjs

# finally stop the collector
kill -TERM ${COLLECTOR_PID}
rm collector.config

wait ${COLLECTOR_PID}

information "Experiment complete."

# end

