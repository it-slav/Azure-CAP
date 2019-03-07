#!/bin/sh
#set -x
. ./set_env.sh
set +x

export MCRGNAME=$(az group list -o table | grep MC_"$RGNAME"_ | awk '{print $1}')
echo -e "\n Resource Group:\t$RGNAME\n \
Public IP:\t\t$(az network public-ip show --resource-group $MCRGNAME --name $AKSNAME-public-ip --query ipAddress)\n \
Private IPs:\t\t\"$(az network nic list --resource-group $MCRGNAME -o json | jq -r '.[].ipConfigurations[].privateIpAddress' | paste -s -d " " | sed -e 's/ /", "/g')\"\n"

