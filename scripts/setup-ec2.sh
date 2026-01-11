#!/bin/bash

# Setup script for EC2 instance to install Minikube and dependencies
# This script should be run on a fresh Ubuntu EC2 instance

set -e

echo "========================================="
echo "Setting up Minikube on EC2 Instance"
echo "========================================="

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi

# Install kubectl
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "kubectl installed successfully"
else
    echo "kubectl is already installed"
fi

# Install Minikube
echo "Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "Minikube installed successfully"
else
    echo "Minikube is already installed"
fi

# Start Minikube
echo "Starting Minikube cluster..."
if ! minikube status &> /dev/null; then
    minikube start --driver=docker --memory=4096 --cpus=2
    echo "Minikube cluster started successfully"
else
    echo "Minikube cluster is already running"
fi

# Enable addons
echo "Enabling Minikube addons..."
minikube addons enable metrics-server
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

# Verify installation
echo "========================================="
echo "Verifying installation..."
echo "========================================="
echo "Docker version:"
docker --version
echo ""
echo "kubectl version:"
kubectl version --client --short
echo ""
echo "Minikube version:"
minikube version
echo ""
echo "Minikube status:"
minikube status
echo ""
echo "Kubernetes cluster info:"
kubectl cluster-info
echo ""
echo "========================================="
echo "Setup completed successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run the deploy-all.sh script to deploy all components"
echo "2. Use port-forward.sh to access Grafana dashboard"
echo ""
