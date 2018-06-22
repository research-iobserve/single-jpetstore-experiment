#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

. $BASE_DIR/common-functions.sh

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	error "Missing configuration"
	exit 1
fi

TYPE="$1"

if [ "$TYPE" == "" ] ; then
	error "type missing"
	exit 1
fi

export DATA_BASE_DIR="$DATA_DIR/$TYPE"
export FIXED_BASE_DIR="$FIXED_DIR/$TYPE"

checkDirectory data-directory

KIEKER_DATA_DIR=`ls "${DATA_BASE_DIR}"`

SOURCE_DIR="$DATA_DIR_DIR/$KIEKER_DATA_DIR"
TARGET_DIR="$FIXED_BASE_DIR/$KIEKER_DATA_DIR"

if [ -d "${FIXED_BASE_DIR}" ] ; then
	rm -rf "${FIXED_BASE_DIR}"
fi

mkdir -p "${FIXED_BASE_DIR}"

cat << EOF > reconstructor.config
## The name of the Kieker instance.
kieker.monitoring.name=$TYPE
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.service.reader=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$DATA_BASE_DIR/$KIEKER_DATA_DIR

#####
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$FIXED_BASE_DIR/$TYPE
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
