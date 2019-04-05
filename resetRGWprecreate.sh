#!/bin/bash
# RESETRGWprecreate.sh    - this requires RHCS 3.1 and later
# adds use of expected_num_objects to pool create (line 32)
# this avoids filestore merge activity while the workloads are active
# not yet adapted to work on runmode==containerized

myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

#------------------------
# BEGIN FUNCTIONS
function delete_pools {
  for pl in ${pool_list[@]}; do
      if [ $pl != "rbd" ]; then
          ceph osd pool delete $pl $pl --yes-i-really-really-mean-it
      fi
  done

  sleep 5
  # Delete the CRUSH rules
  ceph osd crush rule rm default.rgw.buckets.data
  ceph osd crush rule rm bucketindex
}

function create_pools {
  if [ "$1" == "rep" ]; then
      cmdtail="replicated"
  elif [ "$1" == "ec" ]; then
#      cmdtail="erasure myprofile"
# pre-create for 500 Million objects
      cmdtail="erasure myprofile default.rgw.buckets.data 500000000"
      ceph osd erasure-code-profile rm myprofile
      ceph osd erasure-code-profile set myprofile k=$k m=$m 
      ceph osd crush rule create-erasure default.rgw.buckets.data myprofile
  else
      echo "unknown value for REPLICATION in create_pools"; exit
  fi

  for pl in ${pool_list[@]}; do
      if [ $pl == "default.rgw.buckets.data" ]; then
          ceph osd pool create $pl $pg_data $cmdtail
          if [ "$1" == "rep" ]; then
              ceph osd pool set $pl size "${numREPLICAS}"
          fi
      elif [ $pl == "default.rgw.buckets.index" ]; then
      #    Create CRUSH rule for bucketindex on NVMe
          ceph osd crush rule create-replicated bucketindex default host ssd
          ceph osd pool create $pl $pg_index replicated bucketindex
          ceph osd pool set $pl size "${numREPLICAS}"
      else
          ceph osd pool create $pl $pg replicated
          ceph osd pool set $pl size "${numREPLICAS}"
      fi
  done

  CEPH_VERSION=`ceph --version`
  # enable RGW on the pools for RHCS 3.x builds
  if echo $CEPH_VERSION | grep -q "10.2." ; then
    echo "Skip pool enable for 2.5 versions"
  else
    for pool in $(rados lspools); do
       ceph osd pool application enable $pool rgw
    done
  fi
}

# END FUNCTIONS
#------------------------

# not yet adapted to work on runmode==containerized
if [ $runmode == "containerized" ]; then
    error_exit "$LINENO: not yet adapted for runmode=containerized"
fi

echo "$PROGNAME: Running with these values:"
echo "RGWhostname=$RGWhostname r=$REPLICATION k=$k m=$m pgdata=$pg_data pgindex=$pg_index \
      pg=$pg f=$fast_read"

echo "Stopping RGWs"
ansible -m shell -a 'systemctl stop ceph-radosgw@rgw.`hostname -s`.service' rgws

echo "Removing existing/old pools"
delete_pools

echo "Creating new pools"
create_pools $REPLICATION

#echo "sleeping for $longPAUSE seconds..."; sleep "${longPAUSE}"
echo "sleeping for 90 seconds..."; sleep 90

echo "Starting RGWs"
ansible -m shell -a 'systemctl start ceph-radosgw@rgw.`hostname -s`.service' rgws

echo "Creating User - which generates a new Password"
ssh $RGWhostname 'radosgw-admin user create --uid=johndoe --display-name="John Doe" --email=john@example.com' &&
ssh $RGWhostname 'radosgw-admin subuser create --uid=johndoe --subuser=johndoe:swift --access=full' 

# Edit the Password into the XML workload files
echo "inserting new password into XML files $FILLxml, $EMPTYxml, $RUNTESTxml"
key=$(ssh $RGWhostname 'radosgw-admin user info --uid=johndoe | grep secret_key' | tail -1 | awk '{print $2}' | sed 's/"//g')
sed  -i "s/password=.*;/password=$key;/g" ${FILLxml}
sed  -i "s/password=.*;/password=$key;/g" ${EMPTYxml}
sed  -i "s/password=.*;/password=$key;/g" ${RUNTESTxml}

echo "$PROGNAME: Done"	

# DONE
