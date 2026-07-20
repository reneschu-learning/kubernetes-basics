#!/bin/bash

# Install istio base components
echo "Installing istio base components..."
helm install istio-base istio/base -n istio-system --create-namespace --wait

# Install Gateway API CRDs
echo "Installing or updating Gateway API CRDs..."
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml

# Install istio control plane
echo "Installing istio control plane..."
helm install istiod istio/istiod -n istio-system --set profile=ambient --wait

# Install CNI node agent
echo "Installing istio CNI node agent..."
helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait

# Install ztunnel DeamonSet
echo "Installing istio ztunnel DeamonSet..."
helm install ztunnel istio/ztunnel -n istio-system --wait

# Show installation status
helm ls -n istio-system
kubectl get pods -n istio-system
