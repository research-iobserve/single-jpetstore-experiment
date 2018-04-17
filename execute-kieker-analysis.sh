#!/bin/bash

# execute setup

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

if [ ! -x $TRACE_ANALYSIS ] ; then
	echo "Cannot find trace analysis"
	exit 1
fi

if [ ! -x $DOT_PIC ] ; then
	echo "Cannot find dot pic converter"
	exit 1
fi

# kieker analysis
$TRACE_ANALYSIS -i $DATA_DIR/kieker-* --plot-Deployment-Component-Dependency-Graph --plot-Container-Dependency-Graph --plot-Assembly-Component-Dependency-Graph --plot-Aggregated-Deployment-Call-Tree -o analysis

$DOT_PIC $BASE_DIR/analysis svg pdf

# end

