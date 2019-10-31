#!/bin/bash
# writeXML.sh - creates the COSbench workload files
#   fill.xml, measure.xml, age.xml, upgrade.xml

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
#####> COMMENTED - Begin
# Phase 2: EMPTYxml
# backup the XML file if it exists
#if [ -f "${EMPTYxml}" ]; then
#    mv "${EMPTYxml}" "${EMPTYxml}_bak"
#    echo "> ${EMPTYxml} exists - moved to ${EMPTYxml}_bak"
#fi
# copy the Template and make edits
# FILLkeys_arr and FILLvalues_arr defined in vars.shinc
#cp "${EMPTYtemplate}" "${EMPTYxml}"
#
#let index=0
#for origValue in "${FILLkeys_arr[@]}"; do
#    newValue="${FILLvalues_arr[index]}"
#    sed -i "s/${origValue}/${newValue}/g" $EMPTYxml
#    index=$(( $index + 1 ))
#done
#echo "> created COSbench workload file: ${EMPTYxml}"
######### COMMENTED - End

# Phase 2: MEASURExml
# backup the XML file if it exists
if [ -f "${MEASURExml}" ]; then
    mv "${MEASURExml}" "${MEASURExml}_bak"
    echo "> ${MEASURExml} exists - moved to ${MEASURExml}_bak"
fi
# copy the Template and make edits
# MEASUREkeys_arr and MEASUREvalues_arr defined in vars.shinc
cp "${MEASUREtemplate}" "${MEASURExml}"

let index=0
for origValue in "${MEASUREkeys_arr[@]}"; do
    newValue="${MEASUREvalues_arr[index]}"
    sed -i "s/${origValue}/${newValue}/g" $MEASURExml
    index=$(( $index + 1 ))
done
echo "> created COSbench workload file: ${MEASURExml}"

# Phase 3: AGExml
# backup the XML file if it exists
if [ -f "${AGExml}" ]; then
    mv "${AGExml}" "${AGExml}_bak"
    echo "> ${AGExml} exists - moved to ${AGExml}_bak"
fi
# copy the MEASURExml workload and modify the runtime and maxOBJ
cp "${MEASURExml}" "${AGExml}"
sed -i "s/RUNTESTruntime/${AGEruntime}/g" $AGExml
sed -i "s/RUNTESTmaxOBJ/${AGEmaxOBJ}/g" $AGExml
echo "> created COSbench workload file: ${AGExml}"

# Phase 4: UPGRADExml
# backup the XML file if it exists
if [ -f "${UPGRADExml}" ]; then
    mv "${UPGRADExml}" "${UPGRADExml}_bak"
    echo "> ${UPGRADExml} exists - moved to ${UPGRADExml}_bak"
fi
# copy the MEASURExml workload and modify the runtime and maxOBJ
cp "${MEASURExml}" "${UPGRADExml}"
sed -i "s/RUNTESTruntime/${UPGRADEruntime}/g" $UPGRADExml
sed -i "s/RUNTESTmaxOBJ/${UPGRADEmaxOBJ}/g" $UPGRADExml
echo "> created COSbench workload file: ${UPGRADExml}"

# Lastly insert runtime and numOBJ for MEASURE workload
sed -i "s/RUNTESTruntime/${MEASUREruntime}/g" $MEASURExml
sed -i "s/RUNTESTmaxOBJ/${MEASUREmaxOBJ}/g" $MEASURExml


# Complete
echo "DONE - Validate XML files before proceeding."
echo -e "REMEMBER to insert passwd into XML files by running either:\n    resetRGW.sh -or- copyPasswd.sh"

# DONE

