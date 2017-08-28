#!/bin/bash

# configuration

BASE=$(cd "$(dirname "$0")"; pwd)/

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

# match models
for I in graph-em* ; do
	for J in graph-xmeans* ; do
		$EVALUATE_BEHAVIOR -b $I -t $J -o result-$I-$J.txt
	done
done

# end
