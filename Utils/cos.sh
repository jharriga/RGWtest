#!/bin/bash

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD"
fi

# Variables
source "$myPath/../vars.shinc"

# Functions
source "$myPath/../Utils/functions.shinc"

f_name=$1
log=$2
OUTPUT=$(sh $cosPATH/cli.sh submit $f_name) &&
updatelog "$OUTPUT" $log
jobId=$(echo $OUTPUT |awk '{print $4}') &&
updatelog "COSbench jobID is: $jobId - Started" $log

running=1
while [ $running -eq 1 ]; do
    run_path="$cosPATH/archive/$jobId-*"
    if [ -d $run_path ]; then
        running=0
    else
        sleep 10
    fi
done

updatelog "COSbench jobID: $jobId - Completed" $log

## send COSbench jobID value back to caller
echo "${jobId}" > ${TMPfile}

# DONE
