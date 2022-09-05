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

TEMP_DIR="_tmp"

log "CYAN" "Create temp directory"
if [ ! -d $TEMP_DIR ]; then
    mkdir -p $TEMP_DIR
fi

pushd $TEMP_DIR

log "CYAN" "Installing the needed kcp tools"
hw=darwin
KCP_VERSION=0.8.0
wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kcp_${KCP_VERSION}_${hw}_amd64.tar.gz"
wget "https://github.com/kcp-dev/kcp/releases/download/v${KCP_VERSION}/kubectl-kcp-plugin_${KCP_VERSION}_${hw}_amd64.tar.gz"
tar -vxf kcp_${KCP_VERSION}_${hw}_amd64.tar.gz
tar -vxf kubectl-kcp-plugin_${KCP_VERSION}_${hw}_amd64.tar.gz
cp bin/kubectl-* /usr/local/bin

log "CYAN" "Starting the kcp server"
rm -rf .kcp
./bin/kcp start
popd
