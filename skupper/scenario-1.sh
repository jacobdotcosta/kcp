#!/usr/bin/env bash

#
# End to end scenario to test skupper with a kind k8s cluster
#

: ${KIND_CLUSTER_NAME:="skupper"}
: ${K8S_VERSION:=1.20}
: ${HOSTNAME:=1.1.1.1.sslip.io}

SKUPPER_DIR="$(cd $(dirname "${BASH_SOURCE}") && pwd)"

. ${SKUPPER_DIR}/../common.sh
. ${SKUPPER_DIR}/../play-demo.sh


if ! command -v skupper &> /dev/null; then
  warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  warn "skupper is not installed. See: https://skupper.io/start/index.html "
  exit 1
fi

if ! command -v helm &> /dev/null; then
    warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    warn "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
    warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

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

note "Deleting the kind ${KIND_CLUSTER_NAME} cluster"
kind delete cluster --name ${KIND_CLUSTER_NAME}

kindCmd="kind create cluster"
if [ ${K8S_VERSION} == "latest" ]; then
  kindCmd+=""
else
  kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
  jq -r --arg VERSION "$K8S_VERSION" '.[] | select(.k8s == $VERSION).sha')
  kindCmd+=" --image ${kind_image_sha}"
fi

warn "############################################################################################################"
warn "It is needed to create a k8s >=1.20 as the current version of skupper do not yet support the new ingress API"
warn "############################################################################################################"

note "Creating a Kind cluster using the kindest/node image: ${K8S_VERSION}"
echo "${kindCfg}" | ${kindCmd} --config=- --name ${KIND_CLUSTER_NAME}

note "Installing nginx ingress controller using as extra option --enable-ssl-passthrough"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.extraArgs.enable-ssl-passthrough= \
  --set controller.hostPort.enabled=true

note "Wait till ingress rollout succeeded"
k rollout status deployment/ingress-nginx-controller -n ingress

# Parameters to play the scenario
TYPE_SPEED=25
NO_WAIT=true

p "Initializing skupper demo scenario ..."
NAMESPACE1="west"
NAMESPACE2="east"

pe "k create ns west"
pe "k config set-context --current --namespace ${NAMESPACE1}"
pe "skupper init --ingress nginx-ingress-v1 --ingress-host ${HOSTNAME}"

pe "k rollout deployment skupper-service-controller -n ${NAMESPACE1}"
pe "k rollout deployment skupper-router -n ${NAMESPACE1}"
pe "skupper status"

pe "skupper token create ~/west.token"
pe "k create deployment/frontend --image quay.io/skupper/hello-world-frontend"
pe "k expose deployment/frontend --port 8080 --type ClusterIP"
pe "k create ingress frontend --class=nginx --rule=\"frontend.${HOSTNAME}/*=quarkus:80\""