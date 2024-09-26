#!/bin/bash

# Function to check if Podman is installed
check_podman() {
    if ! [ -x "$(command -v podman)" ]; then
        echo "Podman is not installed. Installing Podman..."
        sudo apt-get update
        sudo apt-get install -y podman
    else
        echo "Podman is already installed."
    fi
}

# Function to check if Podman Compose is installed
check_podman_compose() {
    if ! [ -x "$(command -v podman-compose)" ]; then
        echo "Podman Compose is not installed. Installing Podman Compose..."
        sudo apt-get install -y podman-compose
    else
        echo "Podman Compose is already installed."
    fi
}

# Create project directory
setup_directory() {
    echo "Setting up Prometheus-Grafana directory..."
    mkdir -p prometheus-grafana-docker
    cd prometheus-grafana-docker || { echo "Failed to enter directory"; exit 1; }
}

# Create Prometheus configuration file
create_prometheus_config() {
    echo "Creating Prometheus configuration file (prometheus.yml)..."
    cat <<EOT > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']  # Target Prometheus service itself
  - job_name: 'node'
    static_configs:
      - targets: ['node_exporter:9100']  # Target Node Exporter service
EOT
}

# Create Podman Compose file
create_podman_compose_file() {
    echo "Creating Podman Compose file (docker-compose.yml)..."
    cat <<EOT > docker-compose.yml
version: '3.7'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    ports:
      - "9100:9100"
    networks:
      - monitoring

volumes:
  grafana-data:

networks:
  monitoring:
EOT
}

# Start Podman Compose services
start_podman_compose() {
    echo "Starting containers with Podman Compose..."
    podman compose up -d || { echo "Failed to start containers"; exit 1; }
}

# Ensure Podman is running
check_podman_machine() {
    if ! podman machine status | grep -q "running"; then
        echo "Podman machine is not running. Starting Podman machine..."
        podman machine init
        podman machine start
    else
        echo "Podman machine is running."
    fi
}

# Main execution
echo "Starting Prometheus and Grafana Podman setup..."

# Step 1: Check and install Podman if not installed
check_podman

# Step 2: Check and install Podman Compose if not installed
check_podman_compose

# Step 3: Ensure Podman machine is running
check_podman_machine

# Step 4: Set up the project directory
setup_directory

# Step 5: Create configuration files
create_prometheus_config
create_podman_compose_file

# Step 6: Start Podman Compose
start_podman_compose

echo "Prometheus and Grafana setup is complete!"
echo "Prometheus is running on http://localhost:9090"
echo "Grafana is running on http://localhost:3000 (Default login: admin/admin)"
echo "Node Exporter is running on http://localhost:9100"
