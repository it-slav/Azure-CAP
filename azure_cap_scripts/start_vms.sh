#!/bin/sh
#set -x
. ./set_env.sh
set +x


export MCRGNAME=$(az group list -o table | grep MC_"$RGNAME"_ | awk '{print $1}')
export VMNODES=$(az vm list --resource-group $MCRGNAME -o json | jq -r '.[] | select (.tags.poolName ) | .name')

az vm list -d --output table --resource-group $MCRGNAME
echo "Will start VMs, press ENTER to continue"
read

echo
echo "----Starting VMs--------"
for i in $VMNODES
 do
   echo "-----Start VM: $i in resource-group $MCRGNAME---------"
   az vm start -g $MCRGNAME -n $i
done
echo

echo "----VMs status--------"
az vm list -d --output table --resource-group $MCRGNAME

