#!/bin/bash

# execute setup

BASE=$(cd "$(dirname "$0")"; pwd)/

WORKLOADS=$BASE/../../workloads/jpetstore-selenium-workloads/
KIEKER=$BASE/../../kieker-1.12/
IOBSERVE=$BASE/../../analysis.cli-0.0.2-SNAPSHOT/bin/analysis

# analysis


# kieker analysis
$KIEKER/bin/trace-analysis.sh -i $BASE/data/kieker-* --plot-Deployment-Component-Dependency-Graph --plot-Container-Dependency-Graph --plot-Assembly-Component-Dependency-Graph --plot-Aggregated-Deployment-Call-Tree -o analysis

$KIEKER/bin/dotPic-fileConverter.sh $BASE/analysis svg pdf

# end

