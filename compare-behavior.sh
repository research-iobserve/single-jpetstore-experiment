#!/bin/bash

# configuration

BASE=$(cd "$(dirname "$0")"; pwd)/

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

# test setup
if [ ! -x "$EVALUATE_BEHAVIOR" ] ; then
	echo "Behavior evaluation tool missing"
	echo "${EVALUATE_BEHAVIOR} is not pointing to an executable."
	exit 1
fi

if [ ! -d "$AGGREGATE_DIR" ] ; then
	mkdir "$AGGREGATE_DIR"
else
	rm -f "$AGGREGATE_DIR/"*
fi
if [ ! -d "$AGGREGATE_DIR/callinfo" ] ; then
	mkdir "$AGGREGATE_DIR/callinfo"
else
	rm -f "$AGGREGATE_DIR/callinfo/"*
fi
if [ ! -d "$COMPARISON_DIR" ] ; then
	mkdir "$COMPARISON_DIR"
else
	rm -f "$COMPARISON_DIR/"*
fi
if [ ! -d "$IDEAL_MODELS_DIR" ] ; then
	echo "ideal behavior models directory is missing."
	exit 1
fi
if [ ! -d $RESULT_DIR ] ; then
	echo "analysis result directory missing."
	exit 1
fi

# match models
# $1 = mode name, e.g., em, xmeans
function match_models() {
	MODE="$1"
	for I in "$IDEAL_MODELS_DIR/graph-"* ; do
		NAME=`basename $I | cut -c16- | cut -d. -f1`
		OUTPUT="$AGGREGATE_DIR/table-$NAME-$MODE.csv"
		OUTPUT_CALLINFO_BASELINE="$AGGREGATE_DIR/callinfo/table-baseline-$NAME-$MODE-callinfo.csv"
		OUTPUT_CALLINFO_COMPARED="$AGGREGATE_DIR/callinfo/table-compared-$NAME-$MODE-callinfo.csv"

		rm -f "$OUTPUT"
		rm -f "$OUTPUT_CALLINFO"
		echo ";comparison indicator;base n;base e;cmp. n;cmp. e;miss n;add n;miss e;add e;n miss/base;n add/base;e miss/base;e add/base" > "$OUTPUT"
		
		for J in "$RESULT_DIR/graph-$MODE"* ; do
			COMPARE_NAME=`basename $J`
			COMPARISON_FILE="$COMPARISON_DIR/result-$NAME-$COMPARE_NAME.txt"
			$EVALUATE_BEHAVIOR -b "$I" -t "$J" -o "$COMPARISON_FILE"
			cat "$COMPARISON_FILE" | grep "CP" >> "$OUTPUT"
			cat "$COMPARISON_FILE" | grep "baseline" | cut -d\; -f2- | cut -c8- | sed 's/\.txt//g' | sed 's/-graph-/ /g' >> "$OUTPUT_CALLINFO_BASELINE"
			echo "##-------------------------------------" >> "$OUTPUT_CALLINFO_BASELINE"
			cat "$COMPARISON_FILE" | grep "compared" | cut -d\; -f2- | cut -c8- | sed 's/\.txt//g' | sed 's/-graph-/ /g' >> "$OUTPUT_CALLINFO_COMPARED"
			echo "##-------------------------------------" >> "$OUTPUT_CALLINFO_COMPARED"
		done
	done
}

match_models em
match_models xmeans

cd ..

tar -cvzpf $BASE/single-jpetstore-clustering.tgz single-jpetstore-clustering/results single-jpetstore-clustering/aggregates single-jpetstore-clustering/data single-jpetstore-clustering/comparisons single-jpetstore-clustering/ideal-behavior-models single-jpetstore-clustering/pcm

cd $BASE

# end


# end
