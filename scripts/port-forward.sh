#!/bin/bash

# Port forwarding script for accessing Grafana and Prometheus
# This script sets up port forwarding for easy local access

set -e

echo "========================================="
echo "Setting up port forwarding"
echo "========================================="
echo ""
echo "This script will set up port forwarding for:"
echo "  - Grafana: http://localhost:3000"
echo "  - Prometheus: http://localhost:9090"
echo ""
echo "Press Ctrl+C to stop port forwarding"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping port forwarding..."
    kill $GRAFANA_PID $PROMETHEUS_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start Grafana port forwarding
echo "Starting Grafana port forwarding (localhost:3000)..."
kubectl port-forward -n monitoring svc/grafana 3000:3000 > /dev/null 2>&1 &
GRAFANA_PID=$!

# Start Prometheus port forwarding
echo "Starting Prometheus port forwarding (localhost:9090)..."
kubectl port-forward -n monitoring svc/prometheus 9090:9090 > /dev/null 2>&1 &
PROMETHEUS_PID=$!

# Wait a moment for port forwarding to establish
sleep 2

# Check if port forwarding is working
if kill -0 $GRAFANA_PID 2>/dev/null && kill -0 $PROMETHEUS_PID 2>/dev/null; then
    echo ""
    echo "Port forwarding is active!"
    echo ""
    echo "Access services:"
    echo "  Grafana:    http://localhost:3000"
    echo "  Prometheus: http://localhost:9090"
    echo ""
    echo "Grafana credentials:"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "Press Ctrl+C to stop..."
    
    # Wait for user interrupt
    wait
else
    echo "Error: Failed to start port forwarding"
    cleanup
    exit 1
fi
