#!/bin/bash
# finds locally running ceph-osd and ceph-rgw containers
# and returns the current value for Cgroup CPU stat nr_throttled

function get_CGROUPstats() {
  type=$1
  uuid=$2
  starttime=$3

# get current time
  curtime=$(date +%s)

# calc runtime in sec
  rt=$(($curtime-$starttime))

  tt=`grep throttled_time \
     /sys/fs/cgroup/cpu/system.slice/docker-${uuid}.scope/cpu.stat`
  echo "TYPE: $type - runtime $rt sec - $tt nsec \n"
}

# get containers IDs
rgwUID=`docker ps --no-trunc | grep ceph-rgw | awk {'print $1'}`
osdUID=`docker ps --no-trunc | grep ceph-osd | awk {'print $1'} | sed -n 1p`

# get START times for the containers
rgwSTART=`docker inspect --format='{{.State.StartedAt}}' $rgwUID`
osdSTART=`docker inspect --format='{{.State.StartedAt}}' $osdUID`
# convert to sec
rgwEPOCH=$(date --date=$rgwSTART +%s)
osdEPOCH=$(date --date=$osdSTART +%s)

get_CGROUPstats ceph-rgw $rgwUID $rgwEPOCH
# should also do an OSD or two
get_CGROUPstats ceph-osd $osdUID $osdEPOCH


##################################################################
# Time Delta
# start=`date +%s`
# ... do something that takes a while ...
#sleep 11
#
#end=`date +%s`
#let deltatime=end-start
#let hours=deltatime/3600
#let minutes=(deltatime/60)%60
#let seconds=deltatime%60
#printf "Time spent: %d:%02d:%02d\n" $hours $minutes $seconds
