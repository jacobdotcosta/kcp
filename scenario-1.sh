#!/usr/bin/env bash

#
# End to end scenario 1
#
./kcp.sh clean
kind delete cluster
kind create cluster

./kcp.sh install -v 0.8.2
./kcp.sh start

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping the shard workspace"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

./kcp.sh syncer -w my-org
./demo.sh s1




