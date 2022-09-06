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
TEMP_DIR="_tmp"
HW=darwin
KCP_VERSION=0.8.0

log "CYAN" "Create temp directory"
if [ ! -d $TEMP_DIR ]; then
    mkdir -p $TEMP_DIR
fi

pushd $TEMP_DIR

log "CYAN" "Check if kcp is installed"
if [ -f "./bin/kcp" ]; then
  log "CYAN" "kcp is already installed"
else
  log "CYAN" "Installing the needed kcp tools"
  wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kcp_${KCP_VERSION}_${HW}_amd64.tar.gz"
  wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kubectl-kcp-plugin_${KCP_VERSION}_${HW}_amd64.tar.gz"
  tar -vxf kcp_${KCP_VERSION}_${HW}_amd64.tar.gz
  tar -vxf kubectl-kcp-plugin_${KCP_VERSION}_${HW}_amd64.tar.gz
  cp bin/kubectl-* /usr/local/bin
fi

log "CYAN" "Starting the kcp server"
rm -rf .kcp
./bin/kcp start
popd
