#!/bin/bash

# execute setup

BASE=$(cd "$(dirname "$0")"; pwd)/

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

TRACE_ANALYSIS=$KIEKER/bin/trace-analysis.sh
DOT_PIC=$KIEKER/bin/dotPic-fileConverter.sh

if [ ! -d $KIEKER ] ; then
	echo "Missing kieker directory"
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
$TRACE_ANALYSIS -i $DATA/kieker-* --plot-Deployment-Component-Dependency-Graph --plot-Container-Dependency-Graph --plot-Assembly-Component-Dependency-Graph --plot-Aggregated-Deployment-Call-Tree -o analysis

$DOT_PIC $BASE/analysis svg pdf

# end

