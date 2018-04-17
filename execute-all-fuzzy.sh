#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

rm -rf $BASE_DIR/data/*

# NewCustomer

ALL="FishLover,SingleReptileBuyer,SingleCatBuyer,BrowsingUser,AccountManager,CatLover"

for I in `echo $ALL | sed 's/,/ /g'` ; do
	$BASE_DIR/execute-observation.sh $I $I
done

$BASE_DIR/execute-observation.sh $ALL ALL

# end

