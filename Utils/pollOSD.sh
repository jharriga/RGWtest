#!/bin/bash
#
# POLLOSD.sh
#   Polls ceph osd stats and logs stats 
#   Does NOT poll for garbage collection activity
#   writes to LOGFILE
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
[ $# -ne 4 ] && error_exit "POLLosd.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "POLLosd.sh failed - empty first arg"
[ -z "$2" ] && error_exit "POLLosd.sh failed - empty second arg"
[ -z "$3" ] && error_exit "POLLosd.sh failed - empty third arg"
[ -z "$4" ] && error_exit "POLLosd.sh failed - empty fourth arg"

interval=$1          # how long to sleep between polling
log=$2               # the logfile to write to
statcmd=$3
statlog=$4
DATE='date +%Y/%m/%d:%H:%M:%S'

# update log file  
updatelog "** pollOSD started" $log

###########################################################
# append %RAW stats to LOGFILE
get_rawUsed
# bail if cluster gets too full
threshold="85.0"

# keep polling until cluster reaches 'threshold' % fill mark
while (( $(echo "${rawUsed} < ${threshold}" | bc -l) )); do
    # ceph osd daemon cmds
    get_OSDstats "${statcmd}" "${statlog}" "${log}"

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

    # insert polling seperator line
    updatelog "++++++++++++SLEEPING ${interval}++++++++++++++++++++++" $log

    # Sleep for the poll interval
    sleep "${interval}"

    # Record the %RAW USED 
    get_rawUsed

    # Record ceph df stats incl object count
    echo -n "DF: " >> $log
    cephDF=`echo; ceph df | grep rgw.buckets.data`
    updatelog "$cephDF" $log
done

echo -n "pollOSD.sh: " >> $log   # prefix line with label for parsing
updatelog "** 85% fill mark hit: POLL ending" $log

#echo " " | mail -s "pollOSD.sh fill mark hit - terminated" user@company.net

# DONE
