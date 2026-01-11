#!/bin/bash

# Script to create Grafana dashboards ConfigMap from JSON files
# This script reads the dashboard JSON files and creates a ConfigMap

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARDS_DIR="$PROJECT_ROOT/dashboards"
OUTPUT_FILE="$PROJECT_ROOT/manifests/monitoring/grafana-dashboards.yaml"

echo "Creating Grafana dashboards ConfigMap..."

# Start ConfigMap YAML
cat > "$OUTPUT_FILE" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
EOF

# Add each dashboard JSON file to the ConfigMap
for dashboard_file in "$DASHBOARDS_DIR"/*.json; do
    if [ -f "$dashboard_file" ]; then
        filename=$(basename "$dashboard_file")
        echo "  Adding $filename..."
        
        # Escape the JSON content for YAML
        echo "  $(basename "$filename" .json).json: |" >> "$OUTPUT_FILE"
        
        # Add JSON content with proper indentation
        sed 's/^/    /' "$dashboard_file" >> "$OUTPUT_FILE"
    fi
done

echo "Grafana dashboards ConfigMap created at: $OUTPUT_FILE"
