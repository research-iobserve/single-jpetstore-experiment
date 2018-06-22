#!/bin/bash

# configuration

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

. $BASE_DIR/config
. $BASE_DIR/common-functions.sh

# internal data
declare -a CLUSTERINGS

CLUSTERINGS[0]=xmeans
CLUSTERINGS[1]=em
CLUSTERINGS[2]=hierarchy
CLUSTERINGS[3]=similarity

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

function usage() {
	error "Usage: $0 <CLUSTERING> <DATA QUALITY> <EXPERIMENT ID>"
	information "allowed clusterings are:"
	for C in ${CLUSTERINGS[*]} ; do
		information "\t- $C"
	done
	information ""
	information "allowed data qualities"
	information "\t- raw"
	information "\t- fixed"
}

mode=""
for C in ${CLUSTERINGS[*]} ; do
	if [ "$C" == "$1" ] ; then
		mode="$C"
	fi
done

if [ "$2" == "" ] ; then
	error "missing data quality"
	usage
	exit 1
elif [ "$2" == "raw" ] ; then
	USE_DATA_DIR="$DATA_DIR"
elif [ "$2" == "fixed" ] ; then
	USE_DATA_DIR="$FIXED_DIR"
else
	error "illegal type of data-quality $2"
	usage
	exit 1
fi

if [ "$3" == "" ] ; then
	error "missing experiment id"
	usage
	exit 1
else
	if [ ! -d "$USE_DATA_DIR/$3" ] ; then
		error "$3 is not a valid experiment id"
		ls $USE_DATA_DIR
		usage
	else
		USE_DATA_DIR="$USE_DATA_DIR/$3"
	fi
fi

##
# check parameters

if [ "$mode" == "" ] ; then
	error "Unknown clustering $1"
	usage
	exit 1
fi

##
# check script dependencies

checkExecutable analysis "${ANALYSIS}"
checkDirectory data "${DATA_DIR}"
checkDirectory fixed-data "${FIXED_DIR}"
checkDirectory PCM "${PCM_DIR}"
checkDirectory result "${RESULT_DIR}"

echo $USE_DATA_DIR
# compute setup
if [ -f $USE_DATA_DIR/kieker.map ] ; then
	KIEKER_DIRECTORIES=$USE_DATA_DIR
else
	KIEKER_DIRECTORIES=""
	for D in `ls $USE_DATA_DIR` ; do
		if [ -f $USE_DATA_DIR/$D/kieker.map ] ; then
			if [ "$KIEKER_DIRECTORIES" == "" ] ;then
				KIEKER_DIRECTORIES="$USE_DATA_DIR/$D"
			else
				KIEKER_DIRECTORIES="$KIEKER_DIRECTORIES:$USE_DATA_DIR/$D"
			fi
		else
			error "$USE_DATA_DIR/$D is not a kieker log directory."
			exit 1
		fi
	done
fi

information "Kieker directories $KIEKER_DIRECTORIES"

# assemble analysis config
cat << EOF > analysis.config
## The name of the Kieker instance.
kieker.monitoring.name=JIRA
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.analysis.source=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$KIEKER_DIRECTORIES

iobserve.analysis.traces=true
iobserve.analysis.dataFlow=true

iobserve.analysis.model.pcm.directory.db=$DB_DIR
iobserve.analysis.model.pcm.directory.init=$PCM_DIR

# trace preparation (note they should be fixed)
iobserve.analysis.behavior.IEntryCallTraceMatcher=org.iobserve.analysis.systems.jpetstore.JPetStoreCallTraceMatcher
iobserve.analysis.behavior.IEntryCallAcceptanceMatcher=org.iobserve.analysis.systems.jpetstore.JPetStoreTraceAcceptanceMatcher
iobserve.analysis.behavior.ITraceSignatureCleanupRewriter=org.iobserve.analysis.systems.jpetstore.JPetStoreSignatureCleanupRewriter
iobserve.analysis.behavior.IModelGenerationFilterFactory=org.iobserve.analysis.systems.jpetstore.JPetStoreEntryCallRulesFactory

iobserve.analysis.behavior.triggerInterval=1000

iobserve.analysis.behavior.sink.baseUrl=$RESULT_DIR
iobserve.analysis.container.management.sink.visualizationUrl=http://localhost:8080
EOF

case "$mode" in
"${CLUSTERINGS[0]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.expectedUserGroups=1
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.variance=1
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.prefix=jira
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.outputUrl=$RESULT_DIR
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.representativeStrategy=org.iobserve.analysis.systems.jpetstore.JPetStoreRepresentativeStrategy
EOF
;;
"${CLUSTERINGS[1]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.clustering.em.EMBehaviorCompositeStage
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.prefix=jira
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.outputUrl=$RESULT_DIR
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.representativeStrategy=org.iobserve.analysis.systems.jpetstore.JPetStoreRepresentativeStrategy
EOF
;;
"${CLUSTERINGS[2]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behavior.filter=org.iobserve.analysis.clustering.shared.ClassificationCompositeStage
iobserve.analysis.behavior.visualizationUrl=123
iobserve.analysis.behavior.sink.baseUrl=$RESULT_DIR
iobserve.analysis.behavior.classification=org.iobserve.analysis.clustering.birch.BirchClassification
iobserve.analysis.behavior.preprocess.keepTime=1000
iobserve.analysis.behavior.preprocess.minSize=1
iobserve.analysis.behavior.preprocess.keepEmpty=true
iobserve.analysis.behavior.birch.useClusterNumberMetric=true
iobserve.analysis.behavior.birch.clusterMetricStrategy=
iobserve.analysis.behavior.birch.lmethodEvalStrategy=
iobserve.analysis.behavior.birch.leafThreshold=2
iobserve.analysis.behavior.birch.maxLeafSize=7
iobserve.analysis.behavior.birch.maxNodeSize=2
iobserve.analysis.behavior.birch.maxLeafEntries=1
iobserve.analysis.behavior.birch.expectedNumberOfClusters=7
EOF
;;
"${CLUSTERINGS[3]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behavior.filter=org.iobserve.analysis.behavior.clustering.similaritymatching.SimilarityBehaviorCompositeStage
iobserve.analysis.behavior.IClassificationStage=org.iobserve.analysis.behavior.clustering.similaritymatching.SimilarityMatchingStage
iobserve.analysis.behavior.sm.IParameterMetric=org.iobserve.analysis.systems.jpetstore.JPetStoreParameterMetric
iobserve.analysis.behavior.sm.IStructureMetricStrategy=org.iobserve.analysis.behavior.clustering.similaritymatching.GeneralStructureMetric
iobserve.analysis.behavior.sm.IModelGenerationStrategy=org.iobserve.analysis.behavior.clustering.similaritymatching.UnionModelGenerationStrategy
iobserve.analysis.behavior.sm.parameters.radius=2
iobserve.analysis.behavior.sm.structure.radius=2
EOF
;;
esac

# run analysis
information "------------------------"
information "Run analysis"
information "------------------------"

export ANALYSIS_OPTS="-Xmx24g -Xms10m -Dlog4j.configuration=file://$BASE_DIR/log4j.cfg"
$ANALYSIS -c analysis.config

information "Analysis complete."

# end
