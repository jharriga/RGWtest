# GCrate
scripts to investigate RGW garbage collection rates

Uses COSbench to generate RGW operations.
All three scripts report on %RAW USED and Pending GC's
All scripts create logfiles in RESULTS directory

# Inventory of scripts:
- writeXML.sh       writes the three XML files from the Templates (found in 'XMLtemplates' dir)
- resetRGW.sh       resets the RGW env. Deletes pools and creates new user. Injects passwd into XML files
- emptyCluster.sh   invokes emptyWorkload.xml (runs cleanup and dispose operations)
- fillCluster.sh    invokes fillWorkload.xml
- runIOworkload.sh  invokes ioWorkload.xml
- copyPasswd.sh     inserts the RGW password into the three XML workload files
- Utils/pollGC.sh   called by runIOworkload.sh to periodically report stats

NOTE: host IPaddresses and ceph login credentials in vars.shinc will need to be replaced for your cluster

# RUN PROCEDURE:
  - edit vars.shin
  - writeXML.sh
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
