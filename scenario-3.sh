#!/usr/bin/env bash

#
# End to end scenario 3
#

source common.sh

if ! command -v helm &> /dev/null; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

HELM_VERSION=$(helm version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+') || true
if [[ ${HELM_VERSION} < "v3.0.0" ]]; then
  echo "Please upgrade helm to v3.0.0 or higher"
  exit 1
fi

./kcp.sh clean
./kcp.sh install -v ${KCP_VERSION}
./kcp.sh start

# Kind cluster config template
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
)

# Cluster 1 => color: green label
kind delete cluster --name cluster1
echo "${kindCfg}" | kind create cluster --config=- --name cluster1
#
# Install the ingress nginx controller using helm
# Set the Service type as: NodePort (needed for kind)
#
echo "Installing the ingress controller using Helm within the namespace: ingress"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.hostPort.enabled=true

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping root workspace phase 1"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

kubectl ctx kind-cluster1
./kcp.sh syncer -w my-org -c cluster1 -r ingresses.networking.k8s.io,services

./demo.sh s3 -i ${HOSTNAME_IP}



