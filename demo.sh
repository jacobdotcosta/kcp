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

shopt -s expand_aliases
alias k='kubectl'

####################################
## Section to declare the functions
####################################
repeat_char(){
  COLOR=${1}
	for i in {1..70}; do echo -ne "${!COLOR}$2${NC}"; done
}

msg() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "\n${!COLOR}## ${MSG}${NC}"
}

succeeded() {
  echo -e "${GREEN}NOTE:${NC} $1"
}

note() {
  echo -e "${BLUE}NOTE:${NC} $1"
}

warn() {
  echo -e "${YELLOW}WARN:${NC} $1"
}

error() {
  echo -e "${RED}ERROR:${NC} $1"
}

log() {
  MSG="${@:2}"
  echo; repeat_char ${1} '#'; msg ${1} ${MSG}; repeat_char ${1} '#'; echo
}

print_help() {
cat << EOF
Usage:
  $0 <scenario> [args]

Commands:
    s1      Create a workspace, deploy a Quarkus application, move one level up and verify that no deployments exist as workspaces are isolated
    s2      Create a workspace, 2 Placements/locations and apply a label on syncTarget to deploy a Quarkus application on x physical clusters
    s3      Create a workspace, sync an additional resource for Ingress and deploy a Quarkus application

Arguments:
    -h      Display the help
    -t      Temporary folder where kcp is running. Default: _tmp
    -w      Workspace to be used for the demo. Default: my-org
    -v      hostname or ip address of the physical cluster to be used to access ingress routes

Use $0 <scenario> -h for more information about a given scenario.

EOF
}

############################################################################
## Check if flags are passed and set the variables using the flogs passed
############################################################################
if [ "$#" == "0" ]; then
  error "No command passed to $0. Use -h for usage"
  exit 1
fi

ACTION=$1
# note "Action: $ACTION"
shift

############################################################################
## Get the arguments passed to the command
############################################################################
while getopts ":ht:w:v:c:" arg; do
   # note "Arg: ${arg}."
   case ${arg} in
      h) # display Help
         print_help
         exit
         ;;
      t) # Temporary directory where kcp is running
         TEMP_DIR=${OPTARG}
         ;;
      w) # Workspace to sync resources between kcp and target cluster
         KCP_WORKSPACE=${OPTARG}
         ;;
      v) #
         HOSTNAME_IP=${OPTARG}
        ;;
      ?) # Invalid arg
         error "Invalid arg was specified -$OPTARG"
         echo
         print_help
         exit
         ;;
   esac
done

#######################################################
## Set default values when no optional flags are passed
#######################################################
: ${TEMP_DIR:="_tmp"}
: ${KCP_CFG_PATH=.kcp/admin.kubeconfig}
: ${KCP_WORKSPACE=my-org}
: ${KUBE_CFG=$HOME/.kube/config}

pushd $TEMP_DIR
export KUBECONFIG=${KCP_CFG_PATH}

# Actions to executed
case $ACTION in
  -h)
    print_help
    ;;
  s1)
    log "CYAN" "Scenario 1: Create a workspace, deploy an application, move one level up and verify that no deployments exist as workspaces are isolated"
    note "Moving to the root:${KCP_WORKSPACE} workspace"
    note ">> k kcp ws use root:${KCP_WORKSPACE}"
    k kcp ws use root:${KCP_WORKSPACE}

    note "Create a quarkus app within the workspace: ${KCP_WORKSPACE}"
    note ">> k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1"
    k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1
    note ">> k rollout status deployment/quarkus"
    k rollout status deployment/quarkus

    note "Check deployments available within the: $(k kcp workspace .)."
    note ">> k get deployments"
    k get deployments

    note "Moving to the parent workspace which is root"
    note ">> k kcp ws use .."
    k kcp ws use ..

    check_deployment="error: the server doesn't have a resource type \"deployments\""
    if [ "$check_deployment" == "$(k get deployments 2>&1)" ];then
      succeeded "Check succeeded as no deployments were found within the: $(k kcp workspace .)."
    else
      error "Error: deployments found within: $(k kcp workspace .)"
    fi
    ;;
  s2)
    log "CYAN" "Scenario 2: Create a workspace, 2 Placements/locations and apply a label on syncTarget to deploy a Quarkus application on x physical clusters"
    note "Moving to the root:${KCP_WORKSPACE} workspace"
    note ">> k kcp ws use root:${KCP_WORKSPACE}"
    k kcp ws use root:${KCP_WORKSPACE}

    note "Create a quarkus app within the workspace: ${KCP_WORKSPACE}"
    note ">> k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1"
    k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1
    note ">> k rollout status deployment/quarkus"
    k rollout status deployment/quarkus

    note "Check deployments available within the: $(k kcp workspace .)."
    note ">> k get deployments"
    k get deployments

    KUBECONFIG=${KUBE_CFG} k ctx kind-cluster1
    quarkus_pod=$(KUBECONFIG=${KUBE_CFG} k get po -lapp=quarkus -A -o name)
    if [[ $quarkus_pod == pod* ]]; then
      ((counter+=1))
    fi

    KUBECONFIG=${KUBE_CFG} k ctx kind-cluster2
    quarkus_pod=$(KUBECONFIG=${KUBE_CFG} k get po -lapp=quarkus -A -o name)
    if [[ $quarkus_pod == pod* ]]; then
      ((counter+=1))
    fi

    if [[ $counter -eq 2 ]]; then
      succeeded "Check succeeded as $counter Quarkus Application were found on the physical clusters."
    else
      error "Error: $counter deployments found within: $(k kcp workspace .) and not 2."
    fi
    ;;
  s3)
    log "CYAN" "Scenario 2: Create a workspace, 2 Placements/locations and apply a label on syncTarget to deploy a Quarkus application on x physical clusters"
    note "Moving to the root:${KCP_WORKSPACE} workspace"
    note ">> k kcp ws use root:${KCP_WORKSPACE}"
    k kcp ws use root:${KCP_WORKSPACE}

    note "Create a quarkus app within the workspace: ${KCP_WORKSPACE}"
    note ">> k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1"
    k create deployment quarkus --image=quay.io/rhdevelopers/quarkus-demo:v1
    k create service clusterip quarkus --tcp 80:8080
    k create ingress quarkus --class=nginx --rule="quarkus.${HOSTNAME_IP}.sslip.io/*=quarkus:80"

    note ">> k rollout status deployment/quarkus"
    k rollout status deployment/quarkus

    succeeded ">> Curl the ingress route using this address: http://quarkus.${HOSTNAME_IP}.sslip.io/"
    ;;
  *)
    error "Unknown command passed: $ACTION. Please use -h."
    exit 1
esac

popd



