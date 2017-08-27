#!/bin/bash

# configuration

BASE=$(cd "$(dirname "$0")"; pwd)/

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

if [ ! -f $UBM_VISUALIZATION ] ; then
	echo "Missing user behavior visualization"
	exit 1
fi
if [ ! -x $ANALYSIS_CLI ] ; then
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


## startup visualization
echo "------------------------"
echo "Build and start UBM service"
echo "------------------------"
docker-compose -f $UBM_VISUALIZATION build
docker-compose -f $UBM_VISUALIZATION up >& $BASE/docker-compose.log &

# deterime frontend IP address
CID_FRONTEND=`docker ps | grep code_frontend | awk '{ print $1 }'`
HOST_FRONTEND=`docker inspect $CID_FRONTEND | grep IPAddress | tail -1 | sed 's/.*:\ "\(.*\)",/\1/g'`

# deterime logic IP address
CID_LOGIC=`docker ps | grep code_logic | awk '{ print $1 }'`
HOST_LOGIC=`docker inspect $CID_LOGIC | grep IPAddress | tail -1 | sed 's/.*:\ "\(.*\)",/\1/g'`

URL_FRONTEND="http://$HOST_FRONTEND:3000/"
URL_LOGIC="http://$HOST_LOGIC:8080/ubm-backend/v1/"

## wait until service is available
echo "------------------------"
echo "Wait for service"
echo "------------------------"
while ! curl $URL_FRONTEND ; do
        echo "wait frontend"
        sleep 10
	CID_FRONTEND=`docker ps | grep code_frontend | awk '{ print $1 }'`
	HOST_FRONTEND=`docker inspect $CID_FRONTEND | grep IPAddress | tail -1 | sed 's/.*:\ "\(.*\)",/\1/g'`
	URL_FRONTEND="http://$HOST_FRONTEND:3000/"
done
while ! curl $URL_LOGIC ; do
        echo "wait for logic $CID_LOGIC"
        sleep 10
	CID_LOGIC=`docker ps | grep code_logic | awk '{ print $1 }'`
	HOST_LOGIC=`docker inspect $CID_LOGIC | grep IPAddress | tail -1 | sed 's/.*:\ "\(.*\)",/\1/g'`
	URL_LOGIC="http://$HOST_LOGIC:8080/ubm-backend/v1"
done


echo "Both web services are up. Press return to contiune"

read

# run analysis
echo "------------------------"
echo "Run analysis"
echo "------------------------"

$ANALYSIS_CLI -i "$DATA" -p "$PCM" -t 1 -v 4 -u "$URL_LOGIC" 

echo "Analysis complete. Press return to contiune"

read

# stop setup
echo "------------------------"
echo "Terminate"
echo "------------------------"

docker-compose -f $UBM_VISUALIZATION down

# end
