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

USAGE="
Usage:
  $0 <command> [OPTIONS]

Use $0 <command> --help for more information about a given command.

Commands:
    install     Install the kcp server locally and kcp kubectl plugins
    start       Start the kcp server
    stop        Stop the kcp server
    clean     Clean up the temp directory and remove the kcp plugins
"

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

note() {
  echo -e "\n${BLUE}NOTE:${NC} $1"
}

warn() {
  echo -e "\n${YELLOW}WARN:${NC} $1"
}

fixme() {
  echo -e "\n${RED}FIXME:${NC} $1"
}

log() {
  MSG="${@:2}"
  echo; repeat_char ${1} '#'; msg ${1} ${MSG}; repeat_char ${1} '#'; echo
}

check_os() {
  PLATFORM='unknown'
  unamestr=$(uname)
  if [[ "$unamestr" == 'Linux' ]]; then
     PLATFORM='linux'
  elif [[ "$unamestr" == 'Darwin' ]]; then
     PLATFORM='darwin'
  fi
  note "OS type: $PLATFORM"
}

check_cpu() {
  ARCHITECTURE=""
  case $(uname -m) in
      x86_64) ARCHITECTURE="amd64" ;;
      arm*)   ARCHITECTURE="arm64" ;;
  esac
}

############################################################################
## Check if flags are passed and set the variables using the flogs passed
############################################################################
if [[ $# == 0 ]]; then
  fixme "No action were passed. Run with --help flag to get usage information"
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
     -a | --action)
      shift
      action=$1
      shift
      ;;
     -h | --help)
      echo "$HELP_CONTENT"
      exit 1
      ;;
    *)
      fixme "$1 is note a recognized flag!"
      exit 1
      ;;
  esac
done

#######################################################
## Set default values when no optional flags are passed
#######################################################
: ${TEMP_DIR:="_tmp"}
: ${KCP_VERSION=0.8.0}

#######################################################
## Set local default values
#######################################################

# Check OS and cpu
check_os
check_cpu

note "Create temp directory"
if [ ! -d $TEMP_DIR ]; then
    mkdir -p $TEMP_DIR
fi

pushd $TEMP_DIR

# Validate that an action was passed
if ! [[ $action ]]; then
  fixme "Please pass a valid action using the flag (e.g. --action create)"
  exit 1
fi

# Actions to executed
case $action in
  install)
    note "Check if kcp is installed"
    if [ -f "./bin/kcp" ]; then
      warn "kcp is already installed"
    else
      note "Installing the needed kcp tools"
      wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kcp_${KCP_VERSION}_${PLATFORM}_${ARCHITECTURE}.tar.gz"
      wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kubectl-kcp-plugin_${KCP_VERSION}_${PLATFORM}_${ARCHITECTURE}.tar.gz"
      tar -vxf kcp_${KCP_VERSION}_${PLATFORM}_${ARCHITECTURE}.tar.gz
      tar -vxf kubectl-kcp-plugin_${KCP_VERSION}_${PLATFORM}_${ARCHITECTURE}.tar.gz
      cp bin/kubectl-* /usr/local/bin
    fi
    ;;
  start)
    note "Remove previously files created"
    rm -rf .kcp

    if [ -f "./bin/kcp" ]; then
      note "Starting the kcp server"
      ./bin/kcp start &
    else
       warn "kcp is not installed !!"
    fi
    ;;
  stop)
    note "Stopping kcp..."
    pkill kcp
    ;;
  clean)
    note "Stopping kcp..."
    pkill kcp || true
    note "Removing kubectl kcp plugins"
    rm /usr/local/bin/kubectl-{kcp,ws,workspaces}
    note "Deleting temp directory content"
    rm -r *
    ;;
   *)
    fixme "Unknown action passed: $action. Please use --help."
    exit 1
esac

popd
