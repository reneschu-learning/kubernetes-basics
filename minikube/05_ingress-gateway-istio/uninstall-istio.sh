#!/bin/bash

# Uninstall ztunnel DaemonSet
echo "Removing istio ztunnel DaemonSet..."
helm delete ztunnel -n istio-system

# Uninstall CNI node agent
echo "Removing istio CNI node agent..."
helm delete istio-cni -n istio-system

# Uninstall control plane
echo "Removing istio control plane..."
helm delete istiod -n istio-system

# Uninstall istio CRDs
echo "Removing istio CRDs..."
kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete

# Uninstall istio base components
echo "Removing istio base components..."
helm delete istio-base -n istio-system --wait

# Remove istio-system namespace
echo "Removing istio-system namespace..."
kubectl delete namespace istio-system
