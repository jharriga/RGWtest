# RGWtest
scripts to investigate RGW performance and log statistics (garbage collection
rates as well as radosgw and ceph-osd process statistics)

Uses COSbench to issue RGW operations.
All scripts create timestamped logfiles in RESULTS directory

# Inventory of scripts:
- writeXML.sh       writes the three XML files from the Templates (found in 'XMLtemplates' dir)
- resetRGW.sh       resets the RGW env. Deletes pools and creates new user. Inserts passwd into XML files
- emptyCluster.sh   invokes emptyWorkload.xml (runs cleanup and dispose operations)
- fillCluster.sh    invokes fillWorkload.xml
- runIOworkload.sh  invokes ioWorkload.xml
- copyPasswd.sh     inserts the RGW password into the three XML workload files
- Utils/poll.sh     called by runIOworkload.sh to periodically log stats

NOTE: host IPaddresses and ceph login credentials in vars.shinc will need to be replaced for your cluster

# RUN PROCEDURE:
  - edit vars.shinc
  - writeXML.sh        <-- you must run either 'resetRGW.sh' or 'copyPasswd.sh'
  - resetRGW.sh
  - fillCluster.sh
  - runIOworkload.sh
  - emptyCluster.sh

# Calculating the number of objects to use
Based on a cluster with these parameters:
- 174TB of raw capacity
- 10 buckets/containers
- 1MB objext size
- three way replication
the following object count (per container) produces the following fill levels:
- 25% full == 1.45M obj per container, 14.5M total objects
- 50% full == 2.9M objects per container, 29M total objects

Those values were calculated using this formula:
- Raw Capacity of 174TB / 3 = 58TB  (factor in 3way repl)
- 58TB / 10 = 5.8TB   (factor in 10 containers)
- 5.8TB / 1MB = 5.8M object count capacity per container
- 25% of 5.8M is 1.45M objects per container
- 50% of 5.8M is 2.9M objects per container
