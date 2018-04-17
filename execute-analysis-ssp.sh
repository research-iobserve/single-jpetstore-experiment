#!/bin/bash

# configuration

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

if [ "$1" == "xmeans" ] ; then
	echo "Running xmeans"
	MODE="$1"
elif [ "$1" == "em" ] ; then
	echo "Running EM"
	MODE="$1"
else
	echo "Unknown mode $1"
	exit 1
fi

if [ ! -x $ANALYSIS ] ; then
	echo "Missing analysis cli"
	exit 1
fi
if [ ! -d $DATA ] ; then
	echo "Data directory missing"
	exit 1
fi
if [ ! -d $PCM ] ; then
	echo "PCM directory missing"
	exit 1
fi
if [ ! -d "$RESULT_DIR" ] ; then
	mkdir "$RESULT_DIR"
fi

# run analysis
echo "------------------------"
echo "Run analysis"
echo "------------------------"

$ANALYSIS -i "$DATA" -p "$PCM" -t 1 -v 3 -m $MODE -o "${RESULT_DIR}/graph-$MODE-"

# end
