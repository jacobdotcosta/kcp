#!/usr/bin/env bash

#
# End to end scenario 2
#

source common.sh

./kcp.sh clean
./kcp.sh install -v ${KCP_VERSION}
./kcp.sh start

# Cluster 1 => color: green label
kind delete cluster --name cluster1
kind create cluster --name cluster1

# Cluster 2 => color: blue label
kind delete cluster --name cluster2
kind create cluster --name cluster2

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping root workspace phase 1"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

kubectl ctx kind-cluster1
./kcp.sh syncer -w my-org -c cluster1

kubectl ctx kind-cluster2
./kcp.sh syncer -w my-org -c cluster2

KUBECONFIG=_tmp/.kcp/admin.kubeconfig k kcp ws root:my-org
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k label synctarget cluster1 color=green
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k label synctarget cluster2 color=blue

KUBECONFIG=_tmp/.kcp/admin.kubeconfig k delete placement,location --all
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k apply -f ./k8s

./demo.sh s2




