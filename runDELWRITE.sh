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

updatelog "START: cosbench launched" $LOGFILE

# Start the COSbench I/O workload
./Utils/cos.sh ${myPath}/HYBRID_4k64k64m.xml $LOGFILE 

updatelog "END: cosbench done" $LOGFILE

# Record ENDING cluster capacity stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record GC stats
var3=`radosgw-admin gc list --include-all | wc -l`
updatelog "Pending GC's == $var3" $LOGFILE

# END

