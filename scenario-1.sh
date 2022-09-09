#!/usr/bin/env bash

shopt -s expand_aliases
alias k='kubectl'

#
# End to end scenario 1
#
./kcp.sh stop
rm -rf _tmp/
./kcp.sh install -v 0.8.2
./kcp.sh start

kind delete cluster
kind create cluster

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping root workspace phase 1"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

./kcp.sh syncer -w my-org
./demo.sh s1




