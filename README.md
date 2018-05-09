# GCrate
scripts to investigate RGW garbage collection rates

Uses COSbench to generate RGW operations.
All three scripts report on %RAW USED and Pending GC's

Inventory of scripts:
- emptyCluster.sh   invokes emptyWorkload.xml
- fillCluster.sh    invokes fillWorkload.xml
- runDELWRITE.sh    invokes DELWRITE_1M.xml
- Utils/pollGC.sh   called by runDELWRITE.sh to periodically report stats

NOTE: the swift login credentials in each XML file will need to be replaced for your cluster
