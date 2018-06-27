#!/bin/bash
#
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

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE" $LOGFILE

# Record STARTING cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
var3=`radosgw-admin gc list --include-all | wc -l`
updatelog "Pending GC's == $var3" $LOGFILE

updatelog "START: pollGC backgrd process" $LOGFILE
# Poll ceph RGW GC status (in a bkrgd process) 
Utils/pollGC.sh "${pollinterval}" "${LOGFILE}" &
PIDpollGC=$!
# VERIFY it successfully started
sleep 2
if ! ps -p $PIDpollGC > /dev/null; then
    error_exit "pollGC.sh FAILED. Exiting"
fi
updatelog "pollGC backgrd processID $PIDpollGC" $LOGFILE

updatelog "START: cosbench launched" $LOGFILE

# Start the COSbench I/O workload
./Utils/cos.sh ${myPath}/${RUNTESTxml} $LOGFILE 

updatelog "END: cosbench done" $LOGFILE

# Now kill off the POLLCEPH background process
kill $PIDpollGC; kill $PIDpollGC
updatelog "Stopped POLLGC bkgrd process" $LOGFILE

# Record ENDING cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
var3=`radosgw-admin gc list --include-all | wc -l`
updatelog "Pending GC's == $var3" $LOGFILE

# waits for number of pending GCs to reach 1
Utils/completedGC.sh "${pollinterval}" "${LOGFILE}"

# Record FINAL cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE

# END
