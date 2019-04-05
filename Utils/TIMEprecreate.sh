#!/bin/sh
# Test timing for precreate ops
# script expects that an erasure-code-profile named 'myprofile' exists
#

repeat=5
#expectedNumObjects=300000000
expectedNumObjects=500000000
##expectedNumObjects=1000000

echo "Timing precreate for $expectedNumObjects objects : $repeat times"

# remove the CRUSH rule (if it exists)
ceph osd crush rule rm ecCrushRule

# create the CRUSH rule
ceph osd crush rule create-erasure ecCrushRule myprofile

# repeat test $repeat times
for ((i=1; i<=$repeat; i++)); do
# delete existing pool
    ceph osd pool delete testpool testpool \
      --yes-i-really-really-mean-it

# create new pool with expectedNumObjects
##    ceph osd pool create testpool 4096 erasure myprofile \
##      default.rgw.buckets.data "${expectedNumObjects}"
    ceph osd pool create testpool 4096 erasure myprofile \
      ecCrushRule "${expectedNumObjects}"

# time pre-creation, reset interval timer
    SECONDS=0

# pause for pool creation to begin
    sleep 2

# check for keyword 'creating'
    cnt=`ceph -s | grep creating | wc -l`
    while [ "$cnt" != "0" ]; do
        sleep 1
        cnt=`ceph -s | grep creating | wc -l`
    done

# no more 'creating'
    echo "> Pass $i : creating required $SECONDS seconds"
done

# wrap it up
ceph osd pool delete testpool testpool --yes-i-really-really-mean-it
echo "----------"
ceph -s

