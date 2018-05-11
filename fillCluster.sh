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

# Record STARTING cluster capacity snd GC tats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
var3=`radosgw-admin gc list --include-all | wc -l`
updatelog "Pending GC's == $var3" $LOGFILE
########## Alternate stats method
#rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
#pendingGC=`radosgw-admin gc list --include-all | wc -l`
#echo "Starting statistics:"
#echo "   %RAW USED ${rawUsed} : Pending GCs ${pendingGC}" 
#date
##########
# Run the COSbench workload to fill the cluster
updatelog "START: cosbench launched" $LOGFILE
./Utils/cos.sh ${myPath}/${FILLxml} $LOGFILE

# Record ENDING cluster capacity and GC stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
var3=`radosgw-admin gc list --include-all | wc -l`
updatelog "Pending GC's == $var3" $LOGFILE

updatelog "$PROGNAME: Done" $LOGFILE

# DONE
