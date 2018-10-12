#!/bin/bash
# FillCLUSTER.sh

myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

# Functions
source "$myPath/Utils/functions.shinc"

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE" $LOGFILE

# Record STARTING cluster capacity and GC stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
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

##########
# Run the COSbench workload to fill the cluster
updatelog "START: cosbench ${FILLxml} launched" $LOGFILE
./Utils/cos.sh ${myPath}/${FILLxml} $LOGFILE

updatelog "END: cosbench done" $LOGFILE

# Now kill off the POLL background process
kill $PIDpoll; kill $PIDpoll
updatelog "Stopped POLL bkgrd process" $LOGFILE

# Record ENDING cluster capacity and GC stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
get_pendingGC
echo -n "GC: " >> $LOGFILE
updatelog "Pending GC's == $pendingGC" $LOGFILE

updatelog "$PROGNAME: Done" $LOGFILE

# Rename LOGFILE (vars.shinc)
# prepend w/$jobId from cos.sh script (sent via $TMPfile)
updatelog "Renaming LOGFILE with COSbench jobId prefix" $LOGFILE
jobId=$(cat "${TMPfile}")
echo "JOBID: ${jobId}"
LOGFINAL="${RESULTSDIR}/${jobId}_${PROGNAME}_${ts}.log"
echo "LOGFINAL: ${LOGFINAL}"
mv $LOGFILE $LOGFINAL
rm $TMPfile                         # cleanup

# DONE
