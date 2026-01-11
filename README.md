# Kubernetes Monitoring & Logging Dashboard

A complete monitoring and logging solution for Kubernetes clusters using Prometheus, Grafana, and Loki. This project provides a production-ready setup for monitoring cluster health, application metrics, and centralized log aggregation.

## Architecture

The solution consists of:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation system
- **Promtail**: Log collection agent (DaemonSet)
- **Nginx**: Sample application for testing

All components are deployed using plain Kubernetes YAML manifests.

## Prerequisites

- AWS EC2 instance running Ubuntu 20.04 or later
- Minimum 4GB RAM, 2 CPU cores
- Internet connectivity
- SSH access to the EC2 instance

## Quick Start

### 1. Setup EC2 Instance and Minikube

SSH into your EC2 instance and run:

```bash
# Clone the repository (or upload files)
git clone <repository-url>
cd Module-7-Project-Kubernetes-Monitoring-Logging-Dashboard

# Run the setup script
chmod +x scripts/setup-ec2.sh
./scripts/setup-ec2.sh
```

This script will:
- Install Docker, kubectl, and Minikube
- Start a Minikube cluster
- Enable necessary addons

**Note**: After Docker installation, you may need to log out and log back in for group changes to take effect.

### 2. Deploy All Components

```bash
# Deploy all monitoring and logging components
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

This script deploys components in the correct order:
1. Namespaces (monitoring, logging, application)
2. RBAC resources
3. PersistentVolumeClaims
4. Loki (logging infrastructure)
5. Promtail (log collector)
6. Prometheus (metrics collection)
7. Grafana (visualization)
8. Nginx sample application

### 3. Access Grafana

#### Option A: NodePort (Recommended for EC2)

Grafana is exposed via NodePort on port 30000. Access it at:
```
http://<EC2-PUBLIC-IP>:30000
```

#### Option B: Port Forwarding

For local access via port forwarding:

```bash
./scripts/port-forward.sh
```

Then access Grafana at: `http://localhost:3000`

**Default Credentials:**
- Username: `admin`
- Password: `admin`

## Project Structure

```
.
├── manifests/
│   ├── monitoring/          # Prometheus and Grafana manifests
│   │   ├── namespace.yaml
│   │   ├── prometheus-*.yaml
│   │   └── grafana-*.yaml
│   ├── logging/             # Loki and Promtail manifests
│   │   ├── namespace.yaml
│   │   ├── loki-*.yaml
│   │   └── promtail-*.yaml
│   └── application/         # Sample Nginx application
│       ├── nginx-*.yaml
│       └── nginx-namespace.yaml
├── dashboards/              # Grafana dashboard JSON files
│   ├── kubernetes-metrics-dashboard.json
│   └── kubernetes-logs-dashboard.json
├── scripts/                 # Deployment and setup scripts
│   ├── setup-ec2.sh
│   ├── deploy-all.sh
│   ├── port-forward.sh
│   └── create-dashboards-configmap.sh
└── README.md
```

## Grafana Dashboards

### Kubernetes Metrics Dashboard

This dashboard provides comprehensive cluster and application metrics:

#### Panels:

1. **Cluster CPU Usage**
   - Shows CPU usage per pod and namespace
   - Helps identify resource-intensive workloads

2. **Cluster Memory Usage**
   - Displays memory consumption per pod and namespace
   - Useful for capacity planning

3. **Node CPU Usage**
   - CPU utilization per node
   - Helps identify node-level bottlenecks

4. **Node Memory Usage**
   - Memory consumption per node
   - Critical for node resource management

5. **Pod Status**
   - Table view of all pods and their status
   - Shows namespace, pod name, and phase (Running, Pending, etc.)

6. **Node Availability**
   - Stat panel showing number of ready nodes
   - Quick health check indicator

7. **CPU Usage Trend**
   - Historical CPU usage over time
   - Useful for capacity planning and trend analysis

8. **Memory Usage Trend**
   - Historical memory usage over time
   - Helps identify memory growth patterns

### Kubernetes Logs Dashboard

This dashboard provides real-time log visualization and analysis:

#### Panels:

1. **Application Logs - Real-time**
   - Streams logs from the application namespace
   - Auto-refreshes every 10 seconds
   - Shows pod and container information

2. **All Namespaces Logs**
   - Aggregated logs from all namespaces
   - Useful for cluster-wide log analysis

3. **Nginx Pod Logs**
   - Filtered logs specifically from Nginx pods
   - Helps debug application-specific issues

4. **Error Logs**
   - Filters and displays error-level logs
   - Uses LogQL query: `{namespace=~".+"} |= "error" | logfmt`

5. **Log Volume by Namespace**
   - Graph showing log volume trends per namespace
   - Helps identify noisy applications

6. **Log Volume by Pod**
   - Graph showing log volume trends per pod
   - Useful for debugging high-volume loggers

#### LogQL Query Examples:

- View all logs: `{namespace="application"}`
- Filter by pod: `{namespace="application", pod="nginx-xxx"}`
- Search for errors: `{namespace=~".+"} |= "error"`
- Filter by label: `{app="nginx"}`

## Accessing Services

### Grafana
- **NodePort**: `http://<EC2-IP>:30000`
- **Port Forward**: `kubectl port-forward -n monitoring svc/grafana 3000:3000`
- **Credentials**: admin/admin

### Prometheus
- **Port Forward**: `kubectl port-forward -n monitoring svc/prometheus 9090:9090`
- **URL**: `http://localhost:9090`

### Loki
- **Internal**: `http://loki.logging.svc.cluster.local:3100`
- **Port Forward**: `kubectl port-forward -n logging svc/loki 3100:3100`

### Nginx Application
- **Port Forward**: `kubectl port-forward -n application svc/nginx 8080:80`
- **URL**: `http://localhost:8080`

## Troubleshooting

### Pods Not Starting

1. Check pod status:
   ```bash
   kubectl get pods -A
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. Check logs:
   ```bash
   kubectl logs <pod-name> -n <namespace>
   ```

3. Check PVC status:
   ```bash
   kubectl get pvc -A
   ```

### Prometheus Not Scraping Metrics

1. Verify Prometheus configuration:
   ```bash
   kubectl get configmap prometheus-config -n monitoring -o yaml
   ```

2. Check Prometheus targets:
   - Access Prometheus UI
   - Navigate to Status > Targets
   - Verify all targets are UP

### Loki Not Receiving Logs

1. Check Promtail status:
   ```bash
   kubectl get daemonset promtail -n logging
   kubectl logs -n logging -l app=promtail
   ```

2. Verify Promtail configuration:
   ```bash
   kubectl get configmap promtail-config -n logging -o yaml
   ```

3. Check Loki connectivity:
   ```bash
   kubectl exec -n logging -it <promtail-pod> -- wget -O- http://loki.logging.svc.cluster.local:3100/ready
   ```

### Grafana Dashboards Not Loading

1. Verify data sources:
   - Login to Grafana
   - Go to Configuration > Data Sources
   - Verify Prometheus and Loki are configured and accessible

2. Check dashboard ConfigMap:
   ```bash
   kubectl get configmap grafana-dashboards -n monitoring
   ```

3. Regenerate dashboards ConfigMap:
   ```bash
   ./scripts/create-dashboards-configmap.sh
   kubectl apply -f manifests/monitoring/grafana-dashboards.yaml
   kubectl rollout restart deployment/grafana -n monitoring
   ```

### Storage Issues

If PVCs are not binding:

1. Check storage class:
   ```bash
   kubectl get storageclass
   ```

2. For Minikube, ensure storage-provisioner addon is enabled:
   ```bash
   minikube addons enable storage-provisioner
   ```

3. Check PVC status:
   ```bash
   kubectl get pvc -A
   kubectl describe pvc <pvc-name> -n <namespace>
   ```

## Configuration Details

### Prometheus
- **Scrape Interval**: 15 seconds
- **Retention**: 15 days
- **Storage**: 10Gi PVC
- **Scrapes**: Kubernetes API, nodes, pods, cAdvisor, kubelet

### Grafana
- **Default User**: admin
- **Default Password**: admin
- **Storage**: 5Gi PVC
- **Data Sources**: Prometheus (default), Loki

### Loki
- **Retention**: 30 days (720 hours)
- **Storage**: 10Gi PVC
- **Storage Backend**: Filesystem

### Promtail
- **Deployment**: DaemonSet (runs on all nodes)
- **Scrapes**: All pod logs from all namespaces
- **Labels**: Adds Kubernetes metadata (namespace, pod, container, etc.)

## Manual Deployment

If you prefer to deploy components manually:

```bash
# 1. Create namespaces
kubectl apply -f manifests/monitoring/namespace.yaml
kubectl apply -f manifests/logging/namespace.yaml
kubectl apply -f manifests/application/nginx-namespace.yaml

# 2. Deploy RBAC
kubectl apply -f manifests/monitoring/prometheus-rbac.yaml
kubectl apply -f manifests/logging/promtail-rbac.yaml

# 3. Deploy PVCs
kubectl apply -f manifests/monitoring/prometheus-pvc.yaml
kubectl apply -f manifests/monitoring/grafana-pvc.yaml
kubectl apply -f manifests/logging/loki-pvc.yaml

# 4. Deploy Loki
kubectl apply -f manifests/logging/loki-configmap.yaml
kubectl apply -f manifests/logging/loki-service.yaml
kubectl apply -f manifests/logging/loki-statefulset.yaml

# 5. Deploy Promtail
kubectl apply -f manifests/logging/promtail-configmap.yaml
kubectl apply -f manifests/logging/promtail-daemonset.yaml

# 6. Deploy Prometheus
kubectl apply -f manifests/monitoring/prometheus-configmap.yaml
kubectl apply -f manifests/monitoring/prometheus-service.yaml
kubectl apply -f manifests/monitoring/prometheus-deployment.yaml

# 7. Create and deploy Grafana dashboards
./scripts/create-dashboards-configmap.sh
kubectl apply -f manifests/monitoring/grafana-dashboard-configs.yaml
kubectl apply -f manifests/monitoring/grafana-dashboards.yaml

# 8. Deploy Grafana
kubectl apply -f manifests/monitoring/grafana-configmap.yaml
kubectl apply -f manifests/monitoring/grafana-service.yaml
kubectl apply -f manifests/monitoring/grafana-deployment.yaml

# 9. Deploy Nginx
kubectl apply -f manifests/application/nginx-configmap.yaml
kubectl apply -f manifests/application/nginx-service.yaml
kubectl apply -f manifests/application/nginx-deployment.yaml
```

## Cleanup

To remove all deployed components:

```bash
# Delete application
kubectl delete -f manifests/application/

# Delete monitoring stack
kubectl delete -f manifests/monitoring/

# Delete logging stack
kubectl delete -f manifests/logging/

# Delete namespaces (this will delete everything in them)
kubectl delete namespace monitoring logging application
```

## Security Notes

⚠️ **Important**: This setup is configured for development/testing purposes:

- Default Grafana credentials (admin/admin) should be changed in production
- Prometheus and Loki are exposed internally only (ClusterIP services)
- Grafana is exposed via NodePort for easy access
- Consider using Ingress with TLS for production deployments
- Review and adjust RBAC permissions based on your security requirements

## Next Steps

1. **Customize Dashboards**: Import or create custom dashboards in Grafana
2. **Add Alerting**: Configure Prometheus alerting rules and Alertmanager
3. **Scale Components**: Adjust replica counts and resource limits as needed
4. **Add More Applications**: Deploy additional applications to generate more metrics and logs
5. **Production Hardening**: Implement proper authentication, TLS, and backup strategies

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

This project is provided as-is for educational purposes.
