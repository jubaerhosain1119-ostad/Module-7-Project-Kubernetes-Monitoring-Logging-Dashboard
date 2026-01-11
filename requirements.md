Assignment: Kubernetes Monitoring & Logging Dashboard with Grafana and Loki
Objective:
Create a Grafana dashboard to monitor a Kubernetes cluster's health and application logs using Prometheus and Loki. The cluster should be hosted on a Minikube instance inside an AWS EC2 machine.

Requirements:
1. Cluster Setup:
o Deploy a Minikube cluster on an AWS EC2 instance (Ubuntu recommended).

o Ensure the cluster is running at least one sample application in application namespace (e.g., Nginx, custom app, etc.).

2. Monitoring with Prometheus & Grafana:
o Install Prometheus in the cluster to collect metrics.

o Integrate Grafana with Prometheus as a data source.

o Create a Grafana dashboard showing:

§ CPU usage

§ Memory (RAM) usage

§ Pod/Node availability

§ Resource usage trends over time

3. Logging with Loki:
o Deploy Loki and Promtail in the cluster for log aggregation.

o Add Loki as a data source in Grafana.

o Create a log panel in Grafana to visualize real-time application logs using LogQL.

4. Presentation:
o Take clear screenshots of:

§ The EC2 instance setup

§ Minikube cluster running

§ Grafana dashboard with metrics panels

§ Loki log panels

o Submit a PDF report containing:

§ Steps performed

§ Screenshots

§ Dashboard URLs (if public)

§ Challenges faced & how you solved them

5. Bonus (Optional):
o Implement the same setup on Amazon EKS instead of Minikube.

o Highlight the differences in setup/configuration.

 

 

Deliverables:
· A PDF report containing:

o Step-by-step implementation

o Required screenshots

o Brief explanation of each dashboard panel

· (Optional) GitHub repo with configuration files (YAML, dashboards, etc.)