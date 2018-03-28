#!/bin/bash

BASE=$(cd "$(dirname "$0")"; pwd)

rm -rf $BASE/data/*

# NewCustomer

ALL="FishLover,SingleReptileBuyer,SingleCatBuyer,BrowsingUser,AccountManager,CatLover"

for I in `echo $ALL | sed 's/,/ /g'` ; do
	$BASE/execute-observation.sh $I $I
done

$BASE/execute-observation.sh $ALL ALL

# end

