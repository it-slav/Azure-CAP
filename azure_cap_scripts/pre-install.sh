#!/bin/sh
set -x
. ./set_env.sh

echo "----Create Resource Group and AKS Instance 7.2---------------"
az account set --subscription $SUBSCRIPTION_ID

az group create --name $RGNAME --location $REGION

az aks create --kubernetes-version $KUBERNETESVERSION --resource-group $RGNAME --name $AKSNAME --node-count $NODECOUNT --admin-username $ADMINUSERNAME --ssh-key-value $SSHKEYVALUE --node-vm-size $NODEVMSIZE --node-osdisk-size=60 
#az aks create --resource-group $RGNAME --name $AKSNAME --node-count $NODECOUNT --admin-username $ADMINUSERNAME --ssh-key-value $SSHKEYVALUE --node-vm-size $NODEVMSIZE --node-osdisk-size=60 
#az aks create --resource-group $RGNAME --name $AKSNAME --node-count $NODECOUNT --admin-username $ADMINUSERNAME --ssh-key-value $SSHKEYVALUE --node-vm-size $NODEVMSIZE --node-osdisk-size=60 --nodepool-name $NODEPOOLNAME

mv ~/.kube/config ~/.kube/config-az-$NOW.backup
az aks get-credentials --resource-group $RGNAME --name $AKSNAME



echo "-----------------------------------"
echo "VERIFY ALL NODES AND PODS ARE READY!!!"
kubectl get nodes
kubectl get pods --all-namespaces
echo "Press ENTER when ready to continue"
read


echo "------Create Tiller Service account 7.3-----------------------------"
kubectl create serviceaccount tiller --namespace kube-system

kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --upgrade --service-account tiller

kubectl create -f rbac-config.yaml


echo "-------------Apply Pod Security Policies 7.4 - 3.1.1 ----------------------"
kubectl create -f cap-psp-rbac.yaml
echo "----verify new PSPs exist---"
kubectl get psp

helm init --service-account tiller

#exit 0
echo "-----------------------------------"
echo "NEXT STEP ENABLE SWAP"
echo "Press ENTER when ready to continue"
read


echo "---------enable swap accounting 7.5--------"

export MCRGNAME=$(az group list -o table | grep MC_"$RGNAME"_ | awk '{print $1}')

export VMNODES=$(az vm list --resource-group $MCRGNAME -o json | jq -r '.[] | select (.tags.poolName) | .name')
#export VMNODES=$(az vm list --resource-group $MCRGNAME -o json | jq -r '.[] | select (.tags.poolName | contains("'$NODEPOOLNAME'")) | .name')

for i in $VMNODES
 do
   echo "Enable swap host: $i"
   az vm run-command invoke -g $MCRGNAME -n $i --command-id RunShellScript --scripts \
   "sudo sed -i -r 's|^(GRUB_CMDLINE_LINUX_DEFAULT=)\"(.*.)\"|\1\"\2 swapaccount=1\"|' \
   /etc/default/grub.d/50-cloudimg-settings.cfg && sudo update-grub"
   az vm restart -g $MCRGNAME -n $i
done

echo "-----------------------------------"
echo "VERIFY ALL NODES ARE READY!!!"
kubectl get nodes
echo "Press ENTER when ready to continue"
read

exit 0

echo "------create loadbalancer and public ip---------------------"
az network public-ip create --resource-group $MCRGNAME --name $AKSNAME-public-ip --allocation-method Static
az network lb create --resource-group $MCRGNAME --name $AKSNAME-lb --public-ip-address $AKSNAME-public-ip --frontend-ip-name $AKSNAME-lb-front --backend-pool-name $AKSNAME-lb-back

export NICNAMES=$(az network nic list --resource-group $MCRGNAME -o json | jq -r '.[].name')
echo "Nicnames are: $NICNAMES"

for i in $NICNAMES
do
    az network nic ip-config address-pool add --resource-group $MCRGNAME --nic-name $i --ip-config-name ipconfig1 --lb-name $AKSNAME-lb --address-pool $AKSNAME-lb-back
done

echo "--------------create load balancing and Network security rules--------------"
export CAPPORTS="80 443 4443 2222 2793 8443"
for i in $CAPPORTS
do
    az network lb probe create \
    --resource-group $MCRGNAME \
    --lb-name $AKSNAME-lb \
    --name probe-$i \
    --protocol tcp \
    --port $i

    az network lb rule create \
    --resource-group $MCRGNAME \
    --lb-name $AKSNAME-lb \
    --name rule-$i \
    --protocol Tcp \
    --frontend-ip-name $AKSNAME-lb-front \
    --backend-pool-name $AKSNAME-lb-back \
    --frontend-port $i \
    --backend-port $i \
    --probe probe-$i
done

echo "-----------------------------------"
echo "Verify ports"
az network lb rule list --resource-group $MCRGNAME --lb-name $AKSNAME-lb|grep -i port

echo "-----------------------------------"
export AZNSG=$(az network nsg list --resource-group=$MCRGNAME -o json | jq -r '.[].name')
export NSGPRI=200
for i in $CAPPORTS
do
    az network nsg rule create \
    --resource-group $MCRGNAME \
    --priority $NSGPRI \
    --nsg-name $AZNSG \
    --name $AKSNAME-$i \
    --direction Inbound \
    --destination-port-ranges $i \
    --access Allow
    export NSGPRI=$(expr $NSGPRI + 10)
done


echo "---------------Public and Private IP-adresses--------------------"
#echo -e "\n Resource Group:\t$RGNAME\n \
#Public IP:\t\t$(az network public-ip show --resource-group $MCRGNAME --name $AKSNAME-public-ip --query ipAddress)\n \
#Private IPs:\t\t\"$(az network nic list --resource-group $MCRGNAME -o json | jq -r '.[].ipConfigurations[].privateIpAddress' | paste -s -d " " | sed -e 's/ /", "/g')\"\n"

PUBLICIP=$(az network public-ip show --resource-group $MCRGNAME --name $AKSNAME-public-ip --query ipAddress)
PRIVATEIPS=$(az network nic list --resource-group $MCRGNAME -o json | jq -r '.[].ipConfigurations[].privateIpAddress' | paste -s -d " " | sed -e 's/ /", "/g')
echo "Public IP: $PUBLICIP"
echo "Private IPs: \"$PRIVATEIPS\""
echo "Public IP: $PUBLICIP" > ip-addresses.txt
echo "Private IPs: \"$PRIVATEIPS\"">>ip-addresses.txt
echo "--------------------------------------------------------------"
echo "-------------------------Time to deploy CAP-------------------"
echo "--------------------------------------------------------------"
echo "---Verify scf-azure-values.yaml and scf-config-values.yaml---"
echo "----IP addresses in ip-addresses.txt-------------------------"
echo "--------------------------------------------------------------"
