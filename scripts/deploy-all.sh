#!/bin/bash

# Deployment script to deploy all Kubernetes monitoring and logging components
# This script deploys components in the correct order

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "Deploying Kubernetes Monitoring & Logging Stack"
echo "========================================="

# Function to wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    echo "Waiting for $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace || true
}

# Function to wait for statefulset to be ready
wait_for_statefulset() {
    local namespace=$1
    local statefulset=$2
    echo "Waiting for $statefulset in namespace $namespace to be ready..."
    kubectl wait --for=condition=ready --timeout=300s statefulset/$statefulset -n $namespace || true
}

# Step 1: Create namespaces
echo ""
echo "Step 1: Creating namespaces..."
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/namespace.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/namespace.yaml
kubectl apply -f $PROJECT_ROOT/manifests/application/nginx-namespace.yaml
echo "Namespaces created"

# Step 2: Deploy RBAC resources
echo ""
echo "Step 2: Deploying RBAC resources..."
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/prometheus-rbac.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/promtail-rbac.yaml
echo "RBAC resources deployed"

# Step 3: Deploy PersistentVolumeClaims
echo ""
echo "Step 3: Deploying PersistentVolumeClaims..."
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/prometheus-pvc.yaml
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/grafana-pvc.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/loki-pvc.yaml
echo "PVCs deployed"

# Step 4: Deploy Loki (logging infrastructure first)
echo ""
echo "Step 4: Deploying Loki..."
kubectl apply -f $PROJECT_ROOT/manifests/logging/loki-configmap.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/loki-service.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/loki-statefulset.yaml
wait_for_statefulset logging loki
echo "Loki deployed"

# Step 5: Deploy Promtail
echo ""
echo "Step 5: Deploying Promtail..."
kubectl apply -f $PROJECT_ROOT/manifests/logging/promtail-configmap.yaml
kubectl apply -f $PROJECT_ROOT/manifests/logging/promtail-daemonset.yaml
echo "Promtail deployed (DaemonSet will start on all nodes)"

# Step 6: Deploy Prometheus
echo ""
echo "Step 6: Deploying Prometheus..."
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/prometheus-configmap.yaml
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/prometheus-service.yaml
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/prometheus-deployment.yaml
wait_for_deployment monitoring prometheus
echo "Prometheus deployed"

# Step 7: Create Grafana dashboards ConfigMap
echo ""
echo "Step 7: Creating Grafana dashboards ConfigMap..."
$PROJECT_ROOT/scripts/create-dashboards-configmap.sh
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/grafana-dashboard-configs.yaml

# Step 8: Deploy Grafana
echo ""
echo "Step 8: Deploying Grafana..."
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/grafana-configmap.yaml
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/grafana-service.yaml
kubectl apply -f $PROJECT_ROOT/manifests/monitoring/grafana-deployment.yaml
wait_for_deployment monitoring grafana
echo "Grafana deployed"

# Step 9: Deploy sample Nginx application
echo ""
echo "Step 9: Deploying sample Nginx application..."
kubectl apply -f $PROJECT_ROOT/manifests/application/nginx-configmap.yaml
kubectl apply -f $PROJECT_ROOT/manifests/application/nginx-service.yaml
kubectl apply -f $PROJECT_ROOT/manifests/application/nginx-deployment.yaml
wait_for_deployment application nginx
echo "Nginx application deployed"

# Step 10: Verify deployments
echo ""
echo "========================================="
echo "Verifying deployments..."
echo "========================================="
echo ""
echo "Namespaces:"
kubectl get namespaces | grep -E "monitoring|logging|application"
echo ""
echo "Pods in monitoring namespace:"
kubectl get pods -n monitoring
echo ""
echo "Pods in logging namespace:"
kubectl get pods -n logging
echo ""
echo "Pods in application namespace:"
kubectl get pods -n application
echo ""
echo "Services:"
kubectl get svc -n monitoring
kubectl get svc -n logging
kubectl get svc -n application
echo ""
echo "========================================="
echo "Deployment completed!"
echo "========================================="
echo ""
echo "Access Grafana:"
echo "  - NodePort: http://<EC2-IP>:30000"
echo "  - Port-forward: Run ./scripts/port-forward.sh"
echo ""
echo "Default Grafana credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Access Prometheus:"
echo "  - Port-forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo ""
