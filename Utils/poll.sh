#!/bin/bash
#
# POLL.sh
#   Polls ceph and logs stats and writes to LOGFILE
#

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD"
fi

# Variables
source "$myPath/../vars.shinc"

# Functions
# defines: 'get_' routines
source "$myPath/../Utils/functions.shinc"

# check for passed arguments
[ $# -ne 2 ] && error_exit "POLL.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "POLL.sh failed - empty first arg"
[ -z "$2" ] && error_exit "POLL.sh failed - empty second arg"

interval=$1          # how long to sleep between polling
log=$2               # the logfile to write to
DATE='date +%Y/%m/%d:%H:%M:%S'

# update log file  
updatelog "** POLL started" $log

###########################################################
# append GC status to LOGFILE
get_rawUsed
get_pendingGC
echo -n "GC: " >> $log   # prefix line with GC label for parsing
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
threshold="85.0"

# keep polling until cluster reaches 'threshold' % fill mark
#while (( $(awk 'BEGIN {print ("'$rawUsed'" < "'$threshold'")}') )); do
while (( $(echo "${rawUsed} < ${threshold}" | bc -l) )); do
    # RESHARD activity
    echo -n "RESHARD: " >> $log
    get_pendingRESHARD
    updatelog "RESHARDING Queue length ${pendingRESHARD}" $log
    
    # RGW system Load Average
    echo -n "LA: " >> $log        # prefix line with stats label
    get_upTime
    updatelog "${RGWhost} ${upTime}" $log

    # RGW radosgw PROCESS and MEM stats
    echo -n "RGW: " >> $log        # prefix line with stats label`
    get_rgwMem
    updatelog "${RGWhostname} ${rgwMem}" $log

    # ceph-osd PROCESS and MEM stats
    echo -n "OSD: " >> $log        # prefix line with stats label
    get_osdMem
    updatelog "${RGWhostname} ${osdMem}" $log

    # Sleep for the poll interval
    sleep "${interval}"

    # Record the %RAW USED and pending GC count
# NOTE: this may need to be $7 rather than $4 <<<<<<<<
    get_rawUsed
    get_pendingGC
    echo -n "GC: " >> $log
    updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
done

echo -n "POLL.sh: " >> $log   # prefix line with label for parsing
updatelog "** 85% fill mark hit: POLL ending" $log

#echo " " | mail -s "POLL fill mark hit - terminated" user@company.net

# DONE
