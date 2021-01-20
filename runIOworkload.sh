#!/bin/bash
#
# runIOworkload.sh <workload.xml>
# Requires one argument (COSbench workload.xml file)
#####################################################################

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

# Functions
source "$myPath/Utils/functions.shinc"

# Parse cmdline args - we need ONE, the COSbench workload file
[ $# -ne 1 ] && error_exit "runIOworkload.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "runIOworkload.sh failed - empty first arg"

jobfile="$(realpath $1)"
if [ ! -f "${jobfile}" ]; then
    error_exit "$LINENO: Unable to open jobfile: $jobfile."
fi

# Check for COSbench controller
checkCB

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE" $LOGFILE

# log runtime env settings
print_Runtime $LOGFILE

# Add $jobfile contents to LOGFILE
updatelog "BEGIN ${jobfile} contents:" $LOGFILE
cat $jobfile >> $LOGFILE
updatelog "END ${jobfile}" $LOGFILE

# log start Cgroup CPU number throttled (if containerized)
if [ $runmode == "containerized" ]; then
    nt_start=$(ssh $RGWhostname 'bash -s' < Utils/thr_time.sh)
    updatelog "$nt_start" $LOGFILE
fi

# Record STARTING cluster capacity stats
var1=`echo; $execMON ceph df | head -n 5`
var2=`echo; $execMON ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
get_pendingGC
echo -n "GC: " >> $LOGFILE
updatelog "Pending GC's == $pendingGC" $LOGFILE

updatelog "START: poll backgrd process" $LOGFILE
# Poll ceph statistics (in a bkrgd process) 
Utils/poll.sh "${pollinterval}" "${LOGFILE}" &
PIDpoll=$!
# VERIFY it successfully started
sleep 2
if ! ps -p $PIDpoll > /dev/null; then
    error_exit "poll.sh FAILED. Exiting"
fi
updatelog "POLL backgrd processID $PIDpoll" $LOGFILE

updatelog "START: cosbench launched" $LOGFILE

# Start the COSbench I/O workload
# cos.sh passes $jobId back via $TMPfile - used as prefix for $LOGFILE
./Utils/cos.sh $jobfile $LOGFILE

updatelog "END: cosbench done" $LOGFILE

# Now kill off the POLL background process
kill $PIDpoll; kill $PIDpoll
updatelog "Stopped POLL bkgrd process" $LOGFILE

# Record ENDING cluster capacity stats
var1=`echo; $execMON ceph df | head -n 5`
var2=`echo; $execMON ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE

# log end Cgroup CPU number throttled (if containerized)
if [ $runmode == "containerized" ]; then
    nt_end=$(ssh $RGWhostname 'bash -s' < Utils/thr_time.sh)
    updatelog "$nt_end" $LOGFILE
fi

# Record GC stats
get_pendingGC
echo -n "GC: " >> $LOGFILE
updatelog "Pending GC's == $pendingGC" $LOGFILE

###################
# OPTIONAL: waits for number of pending GCs to reach 1
# Utils/completedGC.sh "${pollinterval}" "${LOGFILE}"
# Record FINAL cluster capacity stats
#var1=`echo; $execMON ceph df | head -n 5`
#var2=`echo; $execMON ceph df | grep rgw.buckets.data`
#updatelog "$var1$var2" $LOGFILE
###################

# Rename LOGFILE (vars.shinc)
# prepend w/$jobId from cos.sh script (sent via $TMPfile)
updatelog "Renaming LOGFILE with COSbench jobId prefix" $LOGFILE
jobId=$(cat "${TMPfile}")
echo "JOBID: ${jobId}"
LOGFINAL="${RESULTSDIR}/${jobId}_${PROGNAME}_${ts}.log"
echo "LOGFINAL: ${LOGFINAL}"
mv $LOGFILE $LOGFINAL
rm $TMPfile                         # cleanup

# END
