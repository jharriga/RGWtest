# RGWtest
Scripts to investigate RGW performance and log statistics (garbage collection
rates; radosgw and ceph-osd process stats; as well as "ceph daemon osd" probes)
Detects "runmode", either bare-metal or containerized and prepends ceph cmd calls
appropriately.

Uses COSbench to issue RGW workloads/operations. https://github.com/intel-cloud/cosbench
Scripts create timestamped logfiles in $RESULTS directory, named with prepended COSbench jobId.

# Inventory of scripts:
- writeXML.sh       writes the COSbench XML workload files from the Templates (found in 'XMLtemplates' dir)
- resetRGW.sh       resets the RGW env. Deletes pools and creates new user. Inserts passwd into XML files
- resetRGWbi.sh     variant of 'resetRGW.sh' which uses SSD based bucket indexes (NOTE: does not support runmode=containerized)
- resetRGWprecreate.sh   variant specific to Filestore. Precreates XFS directories for improved workload performance (NOTE: does not support runmode=containerized)
- runIOworkload.sh  invokes ioWorkload.xml (main test script. Executes IOworkload and logs results in RESULTS dir)
- runOSDstats.sh    variant of runIOworkload.sh which polls OSDs for deeper stats gathering (NOTE: does not support runmode=containerized)
- copyPasswd.sh     inserts the RGW password into the COSbench XML workload files

NOTE: host IPaddresses and ceph login credentials in vars.shinc will need to be replaced for your cluster

# RUN PROCEDURE:
  - Edit vars.shinc   MUST BE EDITED (see below)
  - writeXML.sh        <-- afterwards you must run either 'resetRGW.sh' or 'copyPasswd.sh'
  - resetRGW.sh        <- or use one of the two other variants (resetRGWbi.sh; resetRGWprecreate.sh)
  - runIOworkload.sh fillWorkload.xml
  - runIOworkload ioWorkload.xml

# Variables, Utilities and Functions
- vars.shinc: runtime variables for scripts (MUST BE EDITED)
- copyPasswd.sh: inserts the RGW user auth password into the COSbench XML workload files
- Utils/functionshinc: collection of functions called within scripts
- Utils/poll.sh: called by runIOworkload.sh to periodically log statistics (garbage collection, loadAvg, ps...)
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
- 25% of 5.8M is 1.45M objects per container
- 50% of 5.8M is 2.9M objects per container
