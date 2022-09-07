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
  $0 <command> [args]

Commands:
    install     Install the kcp server locally and kcp kubectl plugins
    start       Start the kcp server
    stop        Stop the kcp server
    clean       Clean up the temp directory and remove the kcp plugins

Arguments:
    -v          Version to be installed of the kcp server. E.g: -v 0.8.0
    -t          Temporary folder where kcp will be installed. E.g: -t _tmp

Use $0 <command> -h for more information about a given command.
EOF
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
while getopts ":ht:v:" arg; do
   # note "Arg: ${arg}."
   case ${arg} in
      h) # display Help
         print_help
         exit
         ;;
      v) # Version to be installed
         KCP_VERSION=${OPTARG}
         ;;
      t) # Temporary directory to install kcp
         TEMP_DIR=${OPTARG}
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

# Actions to executed
case $ACTION in
  -h)
    print_help
    ;;
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
    rm /usr/local/bin/kubectl-{kcp,ws,workspaces} || true
    note "Deleting temp directory content"
    rm -r *
    ;;
   *)
    error "Unknown command passed: $ACTION. Please use -h."
    exit 1
esac

popd
