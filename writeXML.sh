#!/bin/bash
# writeXML.sh - creates the COSbench workload files
#   fillWorkload.xml, emptyWorkload.xml, ioWorkload.xml

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

# Functions
#source "$myPath/Utils/functions.shinc"


echo "Creating COSbench XML workload files from settings in vars.shinc"
# Phase 1: FILLxml
# backup the XML file if it exists
if [ -f "${FILLxml}" ]; then
    mv "${FILLxml}" "${FILLxml}_bak"
    echo "> ${FILLxml} exists - moved to ${FILLxml}_bak"
fi
# copy the Template and make edits
# FILLkeys_arr and FILLvalues_arr defined in vars.shinc
cp "${FILLtemplate}" "${FILLxml}"

let index=0
for origValue in "${FILLkeys_arr[@]}"; do
    newValue="${FILLvalues_arr[index]}"
    sed -i "s/${origValue}/${newValue}/g" $FILLxml
    index=$(( $index + 1 ))
done
echo "> created COSbench workload file: ${FILLxml}"

# Phase 2: EMPTYxml
# backup the XML file if it exists
if [ -f "${EMPTYxml}" ]; then
    mv "${EMPTYxml}" "${EMPTYxml}_bak"
    echo "> ${EMPTYxml} exists - moved to ${EMPTYxml}_bak"
fi
# copy the Template and make edits
# FILLkeys_arr and FILLvalues_arr defined in vars.shinc
cp "${EMPTYtemplate}" "${EMPTYxml}"

let index=0
for origValue in "${FILLkeys_arr[@]}"; do
    newValue="${FILLvalues_arr[index]}"
    sed -i "s/${origValue}/${newValue}/g" $EMPTYxml
    index=$(( $index + 1 ))
done
echo "> created COSbench workload file: ${EMPTYxml}"

# Phase 3: RUNTESTxml
# backup the XML file if it exists
if [ -f "${RUNTESTxml}" ]; then
    mv "${RUNTESTxml}" "${RUNTESTxml}_bak"
    echo "> ${RUNTESTxml} exists - moved to ${RUNTESTxml}_bak"
fi
# copy the Template and make edits
# RTkeys_arr and RTvalues_arr defined in vars.shinc
cp "${RUNTESTtemplate}" "${RUNTESTxml}"

let index=0
for origValue in "${RTkeys_arr[@]}"; do
    newValue="${RTvalues_arr[index]}"
    sed -i "s/${origValue}/${newValue}/g" $RUNTESTxml
    index=$(( $index + 1 ))
done
echo "> created COSbench workload file: ${RUNTESTxml}"

echo "DONE - Validate XML files before proceeding."
echo "REMEMBER to insert passwd into XML files by running either:\n    resetRGW.sh -or- copyPasswd.sh"

# DONE
