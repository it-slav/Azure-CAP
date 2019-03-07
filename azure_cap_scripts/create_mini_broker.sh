#!/bin/sh

#Doc is wrong, below works
helm install suse/minibroker --name minibroker --namespace minibroker --set "defaultNamespace=minibroker"

cf create-service-broker minibroker username password http://minibroker-minibroker.minibroker.svc.cluster.local
cf enable-service-access redis
cf enable-service-access mongodb
cf enable-service-access postgresql
cf enable-service-access mariadb

