#!/bin/sh
#set -x

export NOW=`date +%F-%H:%M:%S`
export RGNAME="PeterAndersson-cap-aks"
export AKSNAME="PA"
#export REGION="westeurope" 
export REGION="eastus" #default
#export REGION="eastus2" 
export LOCATION=$REGION #Inconsistent manual uses different variables for the same purpose
export NODECOUNT="3"
#export NODECOUNT="3" #With Standard_D4_v2, 3 should be enough
export NODEVMSIZE="Standard_DS3_v2" #Recommended size
#export NODEVMSIZE="Standard_D4_v2" #old Recommended size
#export NODEVMSIZE="Standard_D3_v2" #Good for labs
export KUBERNETESVERSION=1.11.6 #Get possible version by running az aks get-versions --location eastus
export SSHKEYVALUE="~/.ssh/id_rsa.pub"
export ADMINUSERNAME="scf-admin"
export NODEPOOLNAME="PApool"

export PATH=$PATH:/home/peter/dl/helm/linux-amd64 #Add Helm to path

SBRGNAME=$RGNAME-service-broker




