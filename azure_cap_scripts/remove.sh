#!/bin/sh
set -x
. ./set_env.sh

az group delete --name $RGNAME --yes
az group delete --name $SBRGNAME --yes
#az group delete --name MC_$RGNAM_$AKSNAME_$REGION --yes
