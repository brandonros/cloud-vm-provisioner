#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# load config
. $SCRIPT_PATH/config.sh

KUSTOMIZE_PATH=$SCRIPT_PATH/../kustomize
SERVER_FILES_PATH=$SCRIPT_PATH/../server-files

wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    local timeout=${3:-120s}

    echo "Waiting for deployment $deployment in namespace $namespace..."
    kubectl wait --for=create deployment/$deployment -n $namespace --timeout=$timeout || return 1
    kubectl wait --for=condition=available deployment/$deployment -n $namespace --timeout=$timeout || return 1
    kubectl rollout status deployment/$deployment -n $namespace --watch || return 1
}

# get instance details
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform apply -auto-approve
instance_ipv4=$(terraform output -raw instance_ipv4)
instance_username=$(terraform output -raw instance_username)
instance_ssh_port=$(terraform output -raw ssh_port)
cd ../../

# trust k3s-generated CA
echo "trusting k3s-generated CA"
CERT_NAME="k3s-server-ca"
SYSTEM_KEYCHAIN="/Library/Keychains/System.keychain"
if ! security find-certificate -c "$CERT_NAME" "$SYSTEM_KEYCHAIN" > /dev/null 2>&1; then
  echo "Adding certificate to system keychain..."
  sudo security add-trusted-cert -d -r trustRoot -k "$SYSTEM_KEYCHAIN" "$SERVER_FILES_PATH/server-ca.crt"
fi

# append exposed external services from ingress to /etc/hosts if not already present
echo "adding to /etc/hosts"
HOSTS_ENTRY="$instance_ipv4 grafana.debian-k3s docker-registry.debian-k3s tempo.debian-k3s prometheus.debian-k3s linkerd-viz.debian-k3s graphite.debian-k3s pdf-generator.debian-k3s"
if ! grep -qF "$HOSTS_ENTRY" /etc/hosts; then
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
fi

# check for existing tunnel and spawn if needed
if ! pgrep -f "ssh.*-L 6443:localhost:6443.*$instance_ipv4" > /dev/null; then
    echo "Starting SSH tunnel..."
    ssh -fN -L 6443:localhost:6443 -p $instance_ssh_port $instance_username@$instance_ipv4
else
    echo "SSH tunnel already running"
fi

# copy certs for cert-manager
mkdir -p $KUSTOMIZE_PATH/cert-manager/certs
cp $SERVER_FILES_PATH/server-ca.crt $KUSTOMIZE_PATH/cert-manager/certs/server-ca.crt
cp $SERVER_FILES_PATH/server-ca.key $KUSTOMIZE_PATH/cert-manager/certs/server-ca.key

# set kubeconfig path
KUBECONFIG_PATH=$(readlink -f "$SERVER_FILES_PATH/kubeconfig")
export KUBECONFIG="$KUBECONFIG_PATH"

# workaround traefik needing v1.1.1 gateway-api and linkerd needing v0.8.1 gateway-api crds
if ! kubectl get crd gatewayclasses.gateway.networking.k8s.io -o json | jq -e '.status.storedVersions | contains(["v1beta1"])' >/dev/null
then
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.1/experimental-install.yaml
    kubectl wait --for condition=established --timeout=60s crd/httproutes.gateway.networking.k8s.io
    kubectl wait --for condition=available --timeout=60s deployment/gateway-api-admission-server -n gateway-system
    kubectl rollout status deployment/gateway-api-admission-server -n gateway-system --watch

    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.1/experimental-install.yaml
    kubectl wait --for condition=established --timeout=60s crd/backendlbpolicies.gateway.networking.k8s.io
fi

## metrics-server
echo "deploying metrics-server"
kustomize build $KUSTOMIZE_PATH/metrics-server | envsubst | kubectl apply -f -
wait_for_deployment metrics-server kube-system

## cert-manager
echo "deploying cert-manager"
kustomize build $KUSTOMIZE_PATH/cert-manager | envsubst | kubectl apply -f -
echo "Waiting for cert-manager deployments to be created..."
wait_for_deployment cert-manager cert-manager
wait_for_deployment cert-manager-webhook cert-manager
wait_for_deployment cert-manager-cainjector cert-manager
echo "Waiting for cert-manager CRDs to be established..."
kubectl wait --for=condition=established --timeout=120s crd/clusterissuers.cert-manager.io
kubectl wait --for=condition=established --timeout=120s crd/certificates.cert-manager.io
kubectl wait --for=condition=established --timeout=120s crd/certificaterequests.cert-manager.io
echo "Waiting for cert-manager CA secret to be created..."
kubectl wait --for=create secret/debian-k3s-tls -n cert-manager --timeout=60s

## cert-manager-ca
echo "deploying cert-manager-ca"
kustomize build $KUSTOMIZE_PATH/cert-manager-ca | envsubst | kubectl apply -f -
echo "Waiting for ClusterIssuer to be ready..."
kubectl wait --for=condition=ready clusterissuer/debian-k3s-ca-issuer --timeout=60s

## trust-manager
echo "deploying trust-manager"
kustomize build $KUSTOMIZE_PATH/trust-manager | envsubst | kubectl apply -f -
echo "Waiting for trust-manager deployments to be created..."
wait_for_deployment trust-manager trust-manager
echo "Waiting for trust-manager CRDs to be established..."
kubectl wait --for=condition=established --timeout=120s crd/bundles.trust.cert-manager.io

## traefik
echo "deploying traefik"
kustomize build $KUSTOMIZE_PATH/traefik | envsubst | kubectl apply -f -
wait_for_deployment traefik traefik
echo "Waiting for traefik CA secret to be created..."
kubectl wait --for=create secret/debian-k3s-gateway-tls -n traefik --timeout=60s

## linkerd
echo "deploying linkerd"
kustomize build $KUSTOMIZE_PATH/linkerd | envsubst | kubectl apply -f -
# TODO: wait for linkerd to be ready

## monitoring
echo "deploying monitoring"
kustomize build $KUSTOMIZE_PATH/monitoring | envsubst | kubectl apply -f -
# TODO: wait for monitoring to be ready

## pdf-generator
echo "deploying pdf-generator"
kustomize build $KUSTOMIZE_PATH/pdf-generator | envsubst | kubectl apply -f -
wait_for_deployment pdf-generator pdf-generator

## linkerd-control-plane
echo "deploying linkerd-control-plane"
kustomize build $KUSTOMIZE_PATH/linkerd-control-plane | envsubst | kubectl apply -f -
# TODO: wait for linkerd-control-plane to be ready

## traefik-routes
echo "deploying traefik-routes"
kustomize build $KUSTOMIZE_PATH/traefik-routes | envsubst | kubectl apply -f -
# TODO: wait for traefik-routes to be ready
