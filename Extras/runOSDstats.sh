#!/bin/bash
#
# runOSDstats.sh
#   executes COSbench jobfile (arg1)
#   polls ceph stats incl. OSD (see Utils/pollOSD.sh)
#   NOTE: only works for runmode=baremetal
#         does not support runmode=containerized
#
#   NOTE: does not poll for garbage collection stats (see 
#         runIOworkload.sh and Utils/poll.sh for that
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

# not yet adapted to work on runmode==containerized
if [ $runmode == "containerized" ]; then
    error_exit "$LINENO: not yet adapted for runmode=containerized"
fi

# Parse cmdline args - we need ONE, the COSbench workload file
[ $# -ne 1 ] && error_exit "runOSDstats.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "runOSDstats.sh failed - empty first arg"

jobfile="$(realpath $1)"
if [ ! -f $jobfile ]; then
    error_exit "$LINENO: Unable to open jobfile: $jobfile."
fi

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
> $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE" $LOGFILE

# Add $jobfile contents to LOGFILE
updatelog "BEGIN ${jobfile} contents:" $LOGFILE
cat $jobfile >> $LOGFILE
updatelog "END ${jobfile}" $LOGFILE

# Record STARTING cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE

# Record GC stats
get_pendingGC
echo -n "GC: " >> $LOGFILE
updatelog "Pending GC's == $pendingGC" $LOGFILE

# write the Hostscripts - used for parallel SSH execution
updatelog "START: Writing Hostscripts" $LOGFILE
write_Hostscripts "dump_mempools"
write_Hostscripts "perf dump"
updatelog "COMPLETED: Writing Hostscripts" $LOGFILE

# initiate START event logging
updatelog "initiate START event logging" $LOGFILE
get_OSDstats "meminfo" "$TMPdir/meminfoSTART" $LOGFILE
get_OSDstats "dump_mempools" "$TMPdir/mempoolsSTART" $LOGFILE
get_OSDstats "perf dump" "$TMPdir/perfdumpSTART" $LOGFILE
updatelog "completed START event logging" $LOGFILE

updatelog "START: poll backgrd process" $LOGFILE
# Poll ceph statistics (in a bkrgd process) 
Utils/pollOSD.sh "${pollinterval}" "${LOGFILE}" "dump_mempools"\
 "$TMPdir/mempoolsRUNNING" &
PIDpoll=$!
# VERIFY it successfully started
sleep 2
if ! ps -p $PIDpoll > /dev/null; then
    error_exit "pollOSD.sh FAILED. Exiting"
fi
updatelog "pollOSD backgrd processID $PIDpoll" $LOGFILE

updatelog "START: cosbench launched" $LOGFILE

# Start the COSbench I/O workload
# cos.sh passes $jobId back via $TMPfile - used as prefix for $LOGFILE
./Utils/cos.sh $jobfile $LOGFILE 
#echo "sleeping 300s"    # DEBUG
#sleep 300               # DEBUG

updatelog "END: cosbench done" $LOGFILE

# Now kill off the POLL background process
kill $PIDpoll; kill $PIDpoll
updatelog "Stopped pollOSD bkgrd process" $LOGFILE
sleep 2

# initiate END event logging
updatelog "initiate END event logging" $LOGFILE
get_OSDstats "meminfo" "$TMPdir/meminfoEND" $LOGFILE
get_OSDstats "dump_mempools" "$TMPdir/mempoolsEND" $LOGFILE
get_OSDstats "perf dump" "$TMPdir/perfdumpEND" $LOGFILE
updatelog "completed END event logging" $LOGFILE

# Record ENDING cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE

# Record GC stats
get_pendingGC
echo -n "GC: " >> $LOGFILE
updatelog "Pending GC's == $pendingGC" $LOGFILE

# Rename LOGFILE (vars.shinc)
# prepend w/$jobId from cos.sh script (sent via $TMPfile)
updatelog "Renaming LOGFILE with COSbench jobId prefix" $LOGFILE
jobId=$(cat "${TMPfile}")
echo "JOBID: ${jobId}"
LOGFINAL="${RESULTSDIR}/${jobId}_${PROGNAME}_${ts}.log"
echo "LOGFINAL: ${LOGFINAL}"
mv $LOGFILE $LOGFINAL
rm $TMPfile                         # cleanup

# Rename OSDstats TMPdir (see vars.shinc) 
# prepend w/$jobId

target="$RESULTSDIR/${jobId}numOBJ${numOBJ}"
mv $TMPdir $target

# END
