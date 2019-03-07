#!/bin/sh

set -x
./set_env.sh

echo "------------Deploy SCF--------------"
SECRET=$(kubectl get pods --namespace uaa \
-o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
-o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm install suse/cf --name susecf-scf --namespace scf --values scf-azure-values.yaml --set "secrets.UAA_CA_CERT=${CA_CERT}"
