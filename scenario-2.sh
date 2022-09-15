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

note "Moving to the root:${KCP_WORKSPACE} workspace"
note ">> k kcp ws use root:${KCP_WORKSPACE}"
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k kcp ws use root:${KCP_WORKSPACE}

note "Create a quarkus app within the workspace: ${KCP_WORKSPACE}"
note ">> k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1"
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1
note ">> k rollout status deployment/quarkus"
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k rollout status deployment/quarkus

note "Check deployments available within the: $(KUBECONFIG=_tmp/.kcp/admin.kubeconfig k kcp workspace .)."
note ">> k get deployments"
KUBECONFIG=_tmp/.kcp/admin.kubeconfig k get deployments

KUBECONFIG=${KUBE_CFG} k ctx kind-cluster1
note "Current ws is: $(KUBECONFIG=${KUBE_CFG} k kcp workspace .)"
quarkus_pod=$(KUBECONFIG=${KUBE_CFG} k get po -lapp=quarkus -A -o name)
if [[ $quarkus_pod == pod* ]]; then
  ((counter+=1))
fi

KUBECONFIG=${KUBE_CFG} k ctx kind-cluster2
note "Current ws is: $(KUBECONFIG=${KUBE_CFG} k kcp workspace .)"
quarkus_pod=$(KUBECONFIG=${KUBE_CFG} k get po -lapp=quarkus -A -o name)
if [[ $quarkus_pod == pod* ]]; then
  ((counter+=1))
fi

if [[ $counter -eq 2 ]]; then
  succeeded "Check succeeded as $counter Quarkus Application were found on the physical clusters."
else
  error "Error: $counter deployments found within: $(k kcp workspace .) and not 2."
fi




