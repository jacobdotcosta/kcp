#!/usr/bin/env bash

#
# End to end scenario 2
#
./kcp.sh stop
rm -rf _/tmp
kind delete cluster --name cluster1
kind create cluster --name cluster1

kind delete cluster --name cluster2
kind create cluster --name cluster2

./kcp.sh install -v 0.8.2
./kcp.sh start

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping the shard workspace"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

kubectl ctx kind-cluster1
./kcp.sh syncer -w my-org -c cluster1

kubectl ctx kind-cluster2
./kcp.sh syncer -w my-org -c cluster2

./demo.sh s1




