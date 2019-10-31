#!/bin/bash
# COPYPASSWD.sh

myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

# Edit the Password into the XML workload files
echo "inserting password into XML files $FILLxml, $EMPTYxml, $RUNTESTxml"
key=$($execRGW 'radosgw-admin user info --uid=johndoe | grep secret_key' | tail -1 | awk '{print $2}' | sed 's/"//g')
sed  -i "s/password=.*;/password=$key;/g" ${FILLxml}
sed  -i "s/password=.*;/password=$key;/g" ${MEASURExml}
sed  -i "s/password=.*;/password=$key;/g" ${AGExml}
sed  -i "s/password=.*;/password=$key;/g" ${UPGRADExml}

echo "$PROGNAME: Done"	

# DONE
