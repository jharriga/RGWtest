# GCrate
scripts to investigate RGW garbage collection rates

Uses COSbench to generate RGW operations.
All three scripts report on %RAW USED and Pending GC's

# Inventory of scripts:
- resetRGW.sh       resets the RGW env. Deletes pools and creates new user. Injects passwd into XML files
- emptyCluster.sh   invokes emptyWorkload.xml
- fillCluster.sh    invokes fillWorkload.xml
- runDELWRITE.sh    invokes DELWRITE_1M.xml
- Utils/pollGC.sh   called by runDELWRITE.sh to periodically report stats

NOTE: the swift login credentials in each XML file will need to be replaced for your cluster

# RUN PROCEDURE:
  - resetRGW.sh
  - fillCluster.sh
  - runDELWRITE.sh
  - emptyCluster.sh

# Calculating the number of objects to use
Based on a cluster with these parameters:
- 174TB of raw capacity
- 10 buckets/containers
- 1MB objext size
- three way replication
the following object count (per container) produces the following fill levels:
- 25% full == 
- 50% full == 2.9M objects per container, 29M total objects
Those values were calculated using this formula:
- Raw Capacity of 174TB / 3 = 58TB  (factor in 3way repl)
- 58TB / 10 = 5.8TB   (factor in 10 containers)
- 5.8TB / 1MB = 5.8M object count capacity per container
- 25% of 5.8M is 1.45M objects per container
- 50% of 5.8M is 2.9M objects per container
