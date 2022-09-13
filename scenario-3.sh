#!/usr/bin/env bash

shopt -s expand_aliases
alias k='kubectl'
hostname_ip="192.168.1.90"

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

#
# End to end scenario 3
#
./kcp.sh stop
rm -rf _tmp/
./kcp.sh install -v 0.8.2
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

# echo "To test ingress, execute the following commands:"
# echo "kubectl create deployment demo --image=httpd --port=80; kubectl expose deployment demo"
# echo "kubectl create ingress demo --class=nginx \\"
# echo "   --rule=\"demo.${hostname_ip}.sslip.io/*=demo:80\""
# echo "curl http://demo.${hostname_ip}.sslip.io"
# echo "<html><body><h1>It works!</h1></body></html>"

tail -f _tmp/kcp-output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"finished bootstrapping root workspace phase 1"* ]] && pkill -P $$ tail
done
echo "KCP is started :-)"

kubectl ctx kind-cluster1
./kcp.sh syncer -w my-org -c cluster1 -r ingresses.networking.k8s.io,services

./demo.sh s3 -v ${hostname_ip}



