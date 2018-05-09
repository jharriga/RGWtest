#!/bin/bash
# FillCLUSTER.sh

myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
pendingGC=`radosgw-admin gc list --include-all | wc -l`
echo "Starting statistics:"
echo "   %RAW USED ${rawUsed} : Pending GCs ${pendingGC}" 
date

# Run the COSbench workload to fill the cluster
echo "starting the I/O workload to fill the Ceph cluster"
./Utils/cos.sh "${myPath}/fillWorkload.xml"

echo "$PROGNAME: Done"	

rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
pendingGC=`radosgw-admin gc list --include-all | wc -l`
echo "Ending statistics:"
echo "   %RAW USED ${rawUsed} : Pending GCs ${pendingGC}" 
date

# DONE
