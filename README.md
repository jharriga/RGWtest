# RGWtest
```
Scripts to investigate Ceph RGW performance and log statistics
Detects "runmode", either bare-metal or containerized and prepends ceph cmd calls
appropriately.
Requires that passwd-less SSH is configured to designated MON node and RGW node. Also requires
that ansible be installed on the system.

Uses COSbench to issue RGW workloads/operations. https://github.com/intel-cloud/cosbench
Scripts create timestamped logfiles in $RESULTS directory, named with prepended COSbench jobId.
```
**To test S3, use github.com/jharriga/genXMLs to generate workload files - then use 'runIOworkload.sh <workload.xml>'**

# Inventory of scripts:
- writeXML.sh       writes the COSbench XML workload files (swift auth) from the Templates (found in 'XMLtemplates' dir)
- resetRGW.sh       resets the RGW env. Deletes pools and creates new (swift auth) user. Inserts passwd into XML files
- copyPasswd.sh     inserts the (swift auth) RGW password into the COSbench XML workload files
- runIOworkload.sh  invokes workload.xml (main test script. Executes workload and logs results in RESULTS dir)

# RUN PROCEDURE:
  - Edit vars.shinc   MUST BE EDITED (see below)
  - writeXML.sh        <-- afterwards you must run either 'resetRGW.sh' or 'copyPasswd.sh'
  - resetRGW.sh        <-- swift auth only. Not used with S3 auth
  - runIOworkload.sh <workload.xml>

# Variables, Utilities and Functions
- vars.shinc: runtime variables for scripts (MUST BE EDITED)
- copyPasswd.sh: inserts the RGW user auth password into the COSbench XML workload files
- Utils/functionshinc: collection of functions called within scripts
- Utils/poll.sh: called by runIOworkload.sh to periodically log statistics (garbage collection, loadAvg, ps...)
- Utils/completedGC.sh: optionally called by runIOworkload.sh. Blcoks waiting for all RGW garbage collection activity to complete
- Utils/thr_time.sh: called by resetRGW.sh and runIOworkload.sh to log Cgroup throttled time (only called in containerized env)

# Edits to vars.shinc
All users will need to make edits to this file prior to executing any of the scripts.
The file is extensively commented to help guide the user.
Commonly required edits include these variables:
- MONhostname
- RGWhostname
- objSIZES
- numOBJ
- numCONT
- preparePTYPE
- pg_data
- pg_index
- pg
- cosPATH

# Calculating the number of objects (numOBJ) to use
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
- 58TB / 10 = 5.8TB   (factor in 10 containers : numCONT)
- 5.8TB / 1MB = 5.8M object count capacity per container
- 25% of 5.8M is 1.45M objects per container (numOBJ)
- 50% of 5.8M is 2.9M objects per container (numOBJ)
