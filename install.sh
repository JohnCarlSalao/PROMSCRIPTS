#!/bin/bash

# Function to check if Docker is installed
check_docker() {
    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y docker.io
    else
        echo "Docker is already installed."
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if ! [ -x "$(command -v docker-compose)" ]; then
        echo "Docker Compose is not installed. Installing Docker Compose..."
        sudo apt-get install -y docker-compose
    else
        echo "Docker Compose is already installed."
    fi
}

# Create project directory
setup_directory() {
    echo "Setting up Prometheus-Grafana directory..."
    mkdir -p prometheus-grafana-docker
    cd prometheus-grafana-docker || exit
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

# Create Docker Compose file
create_docker_compose_file() {
    echo "Creating Docker Compose file (docker-compose.yml)..."
    cat <<EOT > docker-compose.yml

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

# Start Docker Compose services
start_docker_compose() {
    echo "Starting Docker containers with Docker Compose..."
    docker-compose up -d
}

# Main execution
echo "Starting Prometheus and Grafana Docker setup..."

# Step 1: Check and install Docker if not installed
check_docker

# Step 2: Check and install Docker Compose if not installed
check_docker_compose

# Step 3: Set up the project directory
setup_directory

# Step 4: Create configuration files
create_prometheus_config
create_docker_compose_file

# Step 5: Start Docker Compose
start_docker_compose

echo "Prometheus and Grafana setup is complete!"
echo "Prometheus is running on http://localhost:9090"
echo "Grafana is running on http://localhost:3000 (Default login: admin/admin)"
echo "Node Exporter is running on http://localhost:9100"
