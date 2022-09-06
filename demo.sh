#!/usr/bin/env bash

set -e

# Defining some colors for output
NC='\033[0m' # No Color
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

newline=$'\n'

shopt -s expand_aliases
alias k='kubectl'

generate_eyecatcher(){
  COLOR=${1}
	for i in {1..50}; do echo -ne "${!COLOR}$2${NC}"; done
}

log_msg() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "\n${!COLOR}## ${MSG}${NC}"
}

log_line() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "${!COLOR}## ${MSG}${NC}"
}

log() {
  MSG="${@:2}"
  echo; generate_eyecatcher ${1} '#'; log_msg ${1} ${MSG}; generate_eyecatcher ${1} '#'; echo
}

# Global variables
KCP_VERSION=0.8.0
KCP_WORKSPACE=my-org
KCP_KUBE_CFG_PATH=.kcp/admin.kubeconfig
CLUSTER_NAME=kind

if ! command -v kind &> /dev/null; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "kind is not installed"
  echo "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
  exit 1
fi

log "CYAN" "Creating a kind cluster"
rm $HOME/.kube/config || true
kind delete cluster
kind create cluster

TEMP_DIR="_tmp"
pushd $TEMP_DIR

log "CYAN" "Create a kcp ${KCP_WORKSPACE} workspace"
KUBECONFIG=${KCP_KUBE_CFG_PATH} k kcp workspace create ${KCP_WORKSPACE} --enter
log "CYAN" "Sync kcp with kind API resources"
KUBECONFIG=${KCP_KUBE_CFG_PATH} k kcp workload sync ${CLUSTER_NAME} --syncer-image ghcr.io/kcp-dev/kcp/syncer:v${KCP_VERSION} -o syncer-kind.yml
log "CYAN" "Deploy kcp syncer on kind"
KUBECONFIG=$HOME/.kube/config k apply -f "syncer-kind.yml"

log "CYAN" "Wait till sync is done"
KUBECONFIG=${KCP_KUBE_CFG_PATH} k wait --for=condition=Ready synctarget/${CLUSTER_NAME}

log "CYAN" "Create a kuard app within the workspace: ${KCP_WORKSPACE}"
KUBECONFIG=${KCP_KUBE_CFG_PATH} k create deployment kuard --image gcr.io/kuar-demo/kuard-amd64:blue
KUBECONFIG=${KCP_KUBE_CFG_PATH} k rollout status deployment/kuard

KUBECONFIG=${KCP_KUBE_CFG_PATH} k get deployments
KUBECONFIG=${KCP_KUBE_CFG_PATH} k kcp ws use ..

check_deployment="error: the server doesn't have a resource type \"deployments\""
if [ "$check_deployment" == "$(KUBECONFIG=${KCP_KUBE_CFG_PATH} k get deployments 2>&1)" ];then
  log "GREEN" "Check succeeded as no deployments are found within the: $(KUBECONFIG=${KCP_KUBE_CFG_PATH} k kcp workspace .)."
else
  log "RED" "Error: deployments found within: $(KUBECONFIG=${KCP_KUBE_CFG_PATH} k kcp workspace .)"
fi

popd




