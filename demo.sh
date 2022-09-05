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

KCP_VERSION=0.8.0

log "CYAN" "Creating a kind cluster"
kind delete cluster
kind create cluster

TEMP_DIR="_tmp"
pushd $TEMP_DIR

log "CYAN" "Create a kcp my-org workspace"
KUBECONFIG=.kcp/admin.kubeconfig k kcp workspace create my-org --enter
log "CYAN" "Sync kcp with kind API resources"
KUBECONFIG=.kcp/admin.kubeconfig k kcp workload sync kind --syncer-image ghcr.io/kcp-dev/kcp/syncer:v${KCP_VERSION} -o syncer-kind.yml
k apply -f "syncer-kind.yml"

sleep 5
log "CYAN" "Create a kuard app"
KUBECONFIG=.kcp/admin.kubeconfig k create deployment kuard --image gcr.io/kuar-demo/kuard-amd64:blue
KUBECONFIG=.kcp/admin.kubeconfig k rollout status deployment/kuard

KUBECONFIG=.kcp/admin.kubeconfig k get deployments
KUBECONFIG=.kcp/admin.kubeconfig k kcp ws use ..

KUBECONFIG=.kcp/admin.kubeconfig k get deployments
popd




