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
KCP_WORKSPACE=my-org
KCP_CFG_PATH=.kcp/admin.kubeconfig
CLUSTER_NAME=kind

TEMP_DIR="_tmp"
pushd $TEMP_DIR

export KUBECONFIG=${KCP_CFG_PATH}

log "CYAN" "Create a kcp ${KCP_WORKSPACE} workspace"
k kcp workspace create ${KCP_WORKSPACE} --enter

log "CYAN" "Create a kuard app within the workspace: ${KCP_WORKSPACE}"
k create deployment kuard --image gcr.io/kuar-demo/kuard-amd64:blue
k rollout status deployment/kuard

log "CYAN" "Check deployments available within the: $(k kcp workspace .)."
k get deployments

log "CYAN" "Moving to the parent workspace which is root"
k kcp ws use ..

check_deployment="error: the server doesn't have a resource type \"deployments\""
if [ "$check_deployment" == "$(k get deployments 2>&1)" ];then
  log "GREEN" "Check succeeded as no deployments are found within the: $(k kcp workspace .)."
else
  log "RED" "Error: deployments found within: $(k kcp workspace .)"
fi

popd




