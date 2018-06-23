#!/bin/bash
#
# COMPLETEDGC.sh
#   Polls ceph and waits for RGW GC to complete
#

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD"
fi

# Variables
source "$myPath/../vars.shinc"

# Functions
source "$myPath/../Utils/functions.shinc"

# check for passed arguments
[ $# -ne 2 ] && error_exit "completedGC.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "completedGC.sh failed - empty first arg"
[ -z "$2" ] && error_exit "completedGC.sh failed - empty second arg"

interval=$1          # how long to sleep between polling
log=$2               # the logfile to write to
DATE='date +%Y/%m/%d:%H:%M:%S'

# update log file with ceph %RAW USED 
updatelog "** completedGC started" $log
rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
pendingGC=`radosgw-admin gc list --include-all | wc -l`
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
threshold="75.0"

# wait till cluster GC # pending operations is 1
pendingGC=`radosgw-admin gc list --include-all | wc -l`
while [ "$pendingGC" != "1" ]; do
    sleep "${interval}"
    # Record the %RAW USED and pending GC count
    rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
    pendingGC=`radosgw-admin gc list --include-all | wc -l`
    updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
done

updatelog "** Completed RGW GC: completedGC ending" $log

