#!/bin/bash

# Helm deployment script to deploy all Kubernetes monitoring and logging components
# This script uses Helm to deploy all components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHART_DIR="$PROJECT_ROOT/charts/kubernetes-monitoring"
RELEASE_NAME="${RELEASE_NAME:-kubernetes-monitoring}"

echo "========================================="
echo "Deploying Kubernetes Monitoring & Logging Stack with Helm"
echo "========================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed. Please install Helm first."
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if values file exists
VALUES_FILE="${1:-$PROJECT_ROOT/charts/kubernetes-monitoring/values.yaml}"
if [ ! -f "$VALUES_FILE" ]; then
    echo "Warning: Values file not found at $VALUES_FILE, using defaults"
    VALUES_FILE=""
fi

# Function to wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    echo "Waiting for $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace 2>/dev/null || true
}

# Function to wait for statefulset to be ready
wait_for_statefulset() {
    local namespace=$1
    local statefulset=$2
    echo "Waiting for $statefulset in namespace $namespace to be ready..."
    kubectl wait --for=condition=ready --timeout=300s statefulset/$statefulset -n $namespace 2>/dev/null || true
}

# Deploy using Helm
echo ""
echo "Deploying with Helm..."
if [ -n "$VALUES_FILE" ]; then
    echo "Using values file: $VALUES_FILE"
    helm upgrade --install $RELEASE_NAME $CHART_DIR \
        --namespace default \
        --create-namespace \
        -f "$VALUES_FILE" \
        --wait \
        --timeout 10m
else
    echo "Using default values"
    helm upgrade --install $RELEASE_NAME $CHART_DIR \
        --namespace default \
        --create-namespace \
        --wait \
        --timeout 10m
fi

echo ""
echo "Helm deployment completed!"

# Wait for components to be ready
echo ""
echo "Waiting for components to be ready..."

if kubectl get namespace monitoring &> /dev/null; then
    if kubectl get deployment prometheus -n monitoring &> /dev/null; then
        wait_for_deployment monitoring prometheus
    fi
    if kubectl get deployment grafana -n monitoring &> /dev/null; then
        wait_for_deployment monitoring grafana
    fi
fi

if kubectl get namespace logging &> /dev/null; then
    if kubectl get statefulset loki -n logging &> /dev/null; then
        wait_for_statefulset logging loki
    fi
fi

if kubectl get namespace application &> /dev/null; then
    if kubectl get deployment nginx -n application &> /dev/null; then
        wait_for_deployment application nginx
    fi
fi

# Verify deployments
echo ""
echo "========================================="
echo "Verifying deployments..."
echo "========================================="
echo ""
echo "Helm release status:"
helm list -n default | grep $RELEASE_NAME || echo "Release not found in default namespace"
echo ""
echo "Namespaces:"
kubectl get namespaces | grep -E "monitoring|logging|application" || echo "No namespaces found"
echo ""
if kubectl get namespace monitoring &> /dev/null; then
    echo "Pods in monitoring namespace:"
    kubectl get pods -n monitoring || echo "No pods found"
    echo ""
    echo "Services in monitoring namespace:"
    kubectl get svc -n monitoring || echo "No services found"
fi
echo ""
if kubectl get namespace logging &> /dev/null; then
    echo "Pods in logging namespace:"
    kubectl get pods -n logging || echo "No pods found"
    echo ""
    echo "Services in logging namespace:"
    kubectl get svc -n logging || echo "No services found"
fi
echo ""
if kubectl get namespace application &> /dev/null; then
    echo "Pods in application namespace:"
    kubectl get pods -n application || echo "No pods found"
    echo ""
    echo "Services in application namespace:"
    kubectl get svc -n application || echo "No services found"
fi

echo ""
echo "========================================="
echo "Deployment completed!"
echo "========================================="
echo ""
echo "Access Grafana:"
GRAFANA_NODEPORT=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30000")
echo "  - NodePort: http://<EC2-IP>:$GRAFANA_NODEPORT"
echo "  - Port-forward: Run ./scripts/port-forward.sh"
echo ""
echo "Grafana credentials (from values.yaml):"
ADMIN_USER=$(grep -A 1 "admin:" "$CHART_DIR/values.yaml" | grep "user:" | awk '{print $2}' | tr -d '"' || echo "admin")
ADMIN_PASS=$(grep -A 1 "admin:" "$CHART_DIR/values.yaml" | grep "password:" | awk '{print $2}' | tr -d '"' || echo "admin")
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PASS"
echo ""
echo "Access Prometheus:"
echo "  - Port-forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo ""
echo "To upgrade or modify the deployment:"
echo "  helm upgrade $RELEASE_NAME $CHART_DIR -f <values-file>"
echo ""
echo "To uninstall:"
echo "  helm uninstall $RELEASE_NAME"
