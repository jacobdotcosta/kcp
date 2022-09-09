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
    s1      Create a workspace, deploy an application, move one level up and verify that no deployments exist as workspaces are isolated

Arguments:
    -h      Display the help
    -t      Temporary folder where kcp is running. Default: _tmp
    -w      Workspace to be used for the demo. Default: my-org

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

    note "Create a kuard app within the workspace: ${KCP_WORKSPACE}"
    note ">> k create deployment kuard --image gcr.io/kuar-demo/kuard-amd64:blue"
    k create deployment kuard --image gcr.io/kuar-demo/kuard-amd64:blue
    note ">> k rollout status deployment/kuard"
    k rollout status deployment/kuard

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
  *)
    error "Unknown command passed: $ACTION. Please use -h."
    exit 1
esac

popd



