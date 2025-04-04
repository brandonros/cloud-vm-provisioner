#!/bin/bash

export KUBECONFIG="/home/debian/.kube/config"

# Check if the CRD exists and capture the return code without showing errors
if ! kubectl get crd gatewayclasses.gateway.networking.k8s.io &>/dev/null; then
    echo "Gateway API CRD not found. Installing..."
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
    kubectl wait --for condition=established --timeout=60s crd/gatewayclasses.gateway.networking.k8s.io
fi

echo "Gateway API setup complete."
