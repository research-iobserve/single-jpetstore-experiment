#!/bin/bash

# configuration

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

if [ -f $BASE_DIR/common-functions.sh ] ; then
	. $BASE_DIR/common-functions.sh
else
	echo "Missing common-functions"
	exit 1
fi


# check the dirs
if [ ! -d "$COMPARISON_DIR" ] ; then
	mkdir "$COMPARISON_DIR"
else
	rm -f "$COMPARISON_DIR/"*
fi



BASELINEFOLDER=$BASE_DIR/ged-ideal-behavior-models
TESTFOLDER=$BASE_DIR/compare-files

CSVFOLDER=$BASE_DIR/csv-comparisons

# check executable
if [ ! -x "$COMPARE_BEHAVIOR_MODELS" ] ; then
	echo "COMPARE_BEHAVIOR_MODELS tool missing"
	echo "${COMPARE_BEHAVIOR_MODELS} is not pointing to an executable."
	exit 1
fi

for I in "$BASELINEFOLDER/"* ; do
	BASELINENAME=`basename $I`
	OUTPUT="$CSVFOLDER/$BASELINENAME.csv"
	rm -f "$OUTPUT"
	echo ";base node;test node;base edge;test edge;base group;test group;base event;test event;node jaccard index; edge jaccard index; graph-edit-distance" > "$OUTPUT"

	for J in "$TESTFOLDER/"* ; do
		COMPARE_NAME=`basename $J`
		COMPARISON_FILE="$COMPARISON_DIR/result-$BASELINENAME-$COMPARE_NAME.txt"
		$COMPARE_BEHAVIOR_MODELS -b "$I" -t "$J" -o "$COMPARISON_FILE" -s "ComparisonOutputStage"
		cat "$COMPARISON_FILE" >> "$OUTPUT"
	done
done
#BASELINE="$RESULT_DIR/single-fixed_cluster_1"
#TEST="$RESULT_DIR/single-fixed_cluster_1"
