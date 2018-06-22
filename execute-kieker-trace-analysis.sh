#!/bin/bash

# execute setup

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

. $BASE_DIR/common-functions.sh

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	error "Missing configuration"
	exit 1
fi

if [ "$1" == "" ] ; then
	error "Usage: $0 <EXPERIMENT ID>"
	exit 1
fi

USE_DATA_DIR="${DATA_DIR}/$1"

checkDirectory "Input data" "${USE_DATA_DIR}"
checkDirectory "Output" "${ANALYSIS_DIR}"
checkExecutable "Kieker trace-analysis" "${TRACE_ANALYSIS}"
checkExecutable "DotPic" "${DOT_PIC}"

# kieker analysis
$TRACE_ANALYSIS -i "${USE_DATA_DIR}"/kieker-* \
	--plot-Deployment-Component-Dependency-Graph \
	--plot-Container-Dependency-Graph \
	--plot-Assembly-Component-Dependency-Graph \
	--plot-Aggregated-Deployment-Call-Tree \
	-o "${ANALYSIS_DIR}"

$DOT_PIC "${ANALYSIS_DIR}" svg pdf

# end

