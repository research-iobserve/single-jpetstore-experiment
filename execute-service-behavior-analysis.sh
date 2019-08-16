#!/bin/bash



BASE_DIR=$(cd "$(dirname "$0")"; pwd)

. $BASE_DIR/config
. $BASE_DIR/common-functions.sh


function usage() {
	error "Usage: $0 <EXPERIMENT ID>"
}

if [ "$1" == "" ] ; then
	error "missing experiment id"
	usage
	exit 1
else
	EXPERIMENT_ID=$1
fi


USE_DATA_DIR="$DATA_DIR/$EXPERIMENT_ID"

checkDirectory result "${RESULT_DIR}"

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

cat << EOF > analysis.config
## The name of the Kieker instance.
kieker.monitoring.name=JIRA
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

kieker.tools.source.LogsReaderCompositeStage.logDirectories=$KIEKER_DIRECTORIES

iobserve.analysis.traces=true
iobserve.analysis.dataFlow=true
iobserve.analysis.singleEventMode=true

iobserve.analysis.model.pcm.directory.db=$DB_DIR
iobserve.analysis.model.pcm.directory.init=$PCM_DIR

# trace preparation (note they should be fixed)
iobserve.analysis.behavior.IEntryCallTraceMatcher=org.iobserve.analysis.systems.jpetstore.JPetStoreCallTraceMatcher
iobserve.analysis.behavior.IEntryCallAcceptanceMatcher=org.iobserve.analysis.systems.jpetstore.JPetStoreTraceAcceptanceMatcher
iobserve.analysis.behavior.ITraceSignatureCleanupRewriter=org.iobserve.analysis.systems.jpetstore.JPetStoreTraceSignatureCleanupRewriter
iobserve.analysis.behavior.IModelGenerationFilterFactory=org.iobserve.analysis.systems.jpetstore.JPetStoreEntryCallRulesFactory

iobserve.analysis.behavior.triggerInterval=2000

org.iobserve.service.behavior.analysis.returnClustering=true
org.iobserve.service.behavior.analysis.returnMedoids=false
org.iobserve.service.behavior.analysis.outputUrl=$RESULT_DIR/$EXPERIMENT_ID
org.iobserve.service.behavior.analysis.epsilon=5
org.iobserve.service.behavior.analysis.minPts=5
org.iobserve.service.behavior.analysis.maxModelAmount=-1
org.iobserve.service.behavior.analysis.nodeInsertionCost=10
org.iobserve.service.behavior.analysis.edgeInsertionCost=5
org.iobserve.service.behavior.analysis.eventGroupInsertionCost=4
EOF

information "start analysis"
information "$SERVICE_BEHAVIOR_ANALYSIS"
checkExecutable service-behavior-analysis "${SERVICE_BEHAVIOR_ANALYSIS}"
export ANALYSIS_OPTS="-Xmx24g -Xms10m -Dlog4j.configuration=file://$BASE_DIR/log4j.cfg"
$SERVICE_BEHAVIOR_ANALYSIS -c analysis.config


rm analysis.config
information "Analysis complete."
information "$RESULT_DIR"
# end
