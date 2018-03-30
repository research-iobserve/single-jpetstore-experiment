#!/bin/bash

BASE=$(cd "$(dirname "$0")"; pwd)

TYPE="$1"

DATA="$BASE/data"
FIXED="$BASE/fixed"

if [ "$TYPE" == "" ] ; then
	echo "type missing"
	exit 1
fi

if [ ! -d "$DATA/$TYPE" ] ; then
	echo "directory does not exist: $DATA/$TYPE"
	exit 1
fi

KIEKER_DATA=`ls $DATA/$TYPE/`

SOURCE="$DATA/$TYPE/$KIEKER_DATA"
TARGET="$FIXED/$TYPE/$KIEKER_DATA"

if [ -d $FIXED/$TYPE ] ; then
	rm -rf $FIXED/$TYPE
fi

mkdir -p $FIXED/$TYPE

cat << EOF > reconstructor.config
## The name of the Kieker instance.
kieker.monitoring.name=$TYPE
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.service.reader=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$DATA/$TYPE/$KIEKER_DATA

#####
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$FIXED/$TYPE
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

$BASE/../reconstructor-0.0.3-SNAPSHOT/bin/reconstructor -c reconstructor.config

# end
