#!/bin/sh
#set -x
. ./set_env.sh
set +x

export LOCATION=$REGION
export AZURE_SUBSCRIPTION_ID=$(az account show | jq -r '.id')
#az group create --name ${SBRGNAME} --location ${LOCATION}
export SERVICE_PRINCIPAL_INFO=$(az ad sp create-for-rbac --name ${SBRGNAME})
export AZURE_TENANT_ID=$(echo ${SERVICE_PRINCIPAL_INFO} | jq -r '.tenant')
export AZURE_CLIENT_ID=$(echo ${SERVICE_PRINCIPAL_INFO} | jq -r '.appId')
export AZURE_CLIENT_SECRET=$(echo ${SERVICE_PRINCIPAL_INFO} | jq -r '.password')
echo SBRGNAME=${SBRGNAME}
echo LOCATION=${LOCATION}
echo AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID} \; AZURE_TENANT_ID=${AZURE_TENANT_ID}\; AZURE_CLIENT_ID=${AZURE_CLIENT_ID}\; AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}

helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm repo update
helm install svc-cat/catalog --name catalog --namespace catalog --set controllerManager.healthcheck.enabled=false --set apiserver.healthcheck.enabled=false
helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
helm repo update
helm install azure/open-service-broker-azure \
--name osba \
--namespace osba \
--set azure.subscriptionId=${AZURE_SUBSCRIPTION_ID} \
--set azure.tenantId=${AZURE_TENANT_ID} \
--set azure.clientId=${AZURE_CLIENT_ID} \
--set azure.clientSecret=${AZURE_CLIENT_SECRET} \
--set azure.defaultLocation=${LOCATION} \
--set redis.persistence.storageClass=default \
--set basicAuth.username=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16) \
--set basicAuth.password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16) --set tls.enabled=false

cf create-service-broker azure $(kubectl get deployment osba-open-service-broker-azure \
--namespace osba -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name == "BASIC_AUTH_USERNAME")].value}') $(kubectl get secret --namespace osba osba-open-service-broker-azure -o jsonpath='{.data.basic-auth-password}' | base64 -d) http://osba-open-service-broker-azure.osba

cf service-access -b azure | \
awk '($2 ~ /basic/) { system("cf enable-service-access " $1 " -p " $2)}'
