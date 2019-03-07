#!/bin/sh
#set -x
. ./set_env.sh

export AZ_RG_NAME=$RGNAME
export AZ_AKS_NAME=$AKSNAME
export NEWPORT=30061

export AZ_MC_RG_NAME=$(az group list -o table | grep MC_"$AZ_RG_NAME"_ | awk '{print $1}')

az network lb probe create \
       --resource-group $AZ_MC_RG_NAME \
       --lb-name $AZ_AKS_NAME-lb \
       --name probe-$NEWPORT \
       --protocol tcp \
       --port $NEWPORT

az network lb rule create \
       --resource-group $AZ_MC_RG_NAME \
       --lb-name $AZ_AKS_NAME-lb \
       --name rule-$NEWPORT \
       --protocol Tcp \
       --frontend-ip-name $AZ_AKS_NAME-lb-front \
       --backend-pool-name $AZ_AKS_NAME-lb-back \
       --frontend-port $NEWPORT \
       --backend-port $NEWPORT \
       --probe probe-$NEWPORT

export AZ_NSG=$(az network nsg list --resource-group=$AZ_MC_RG_NAME | jq -r '.[].name')
export AZ_NSG_PRI=400

az network nsg rule create \
    --resource-group $AZ_MC_RG_NAME \
    --priority $AZ_NSG_PRI \
    --nsg-name $AZ_NSG \
    --name $AZ_AKS_NAME-$NEWPORT \
    --direction Inbound \
    --destination-port-ranges $NEWPORT \
    --access Allow
