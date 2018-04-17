#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

TYPE="$1"

if [ "$TYPE" == "" ] ; then
	echo "type missing"
	exit 1
fi

if [ ! -d "$DATA_DIR/$TYPE" ] ; then
	echo "directory does not exist: $DATA_DIR/$TYPE"
	exit 1
fi

KIEKER_DATA_DIR=`ls $DATA_DIR/$TYPE/`

SOURCE_DIR="$DATA_DIR/$TYPE/$KIEKER_DATA_DIR"
TARGET_DIR="$FIXED_DIR/$TYPE/$KIEKER_DATA_DIR"

if [ -d $FIXED_DIR/$TYPE ] ; then
	rm -rf $FIXED_DIR/$TYPE
fi

mkdir -p $FIXED_DIR/$TYPE

cat << EOF > reconstructor.config
## The name of the Kieker instance.
kieker.monitoring.name=$TYPE
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.service.reader=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$DATA_DIR/$TYPE/$KIEKER_DATA_DIR

#####
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$FIXED_DIR/$TYPE
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
kieker.monitoring.writer.filesystem.FileWriter.compression=kieker.monitoring.writer.filesystem.compression.NoneCompressionFilter
EOF

$RECONSTRUCTOR -c reconstructor.config

# end
