#!/bin/sh

set -x
./set_env.sh

echo "----------Add the Kubernetes charts repository----------------"
helm repo add suse https://kubernetes-charts.suse.com/
helm repo list
helm search suse

echo "----------Create Namespaces----------------"
kubectl create namespace uaa
kubectl create namespace scf


echo "----------Deploy UAA----------------"
helm install suse/uaa --name susecf-uaa --namespace uaa --values scf-azure-values.yaml

echo "----------Wait until all are running----------------"
echo "---------watch -c 'kubectl get pods --namespace uaa'--------"
echo "---------test with curl -k https://uaa.cap.suselinux.info:2793/.well-known/openid-configuration"
