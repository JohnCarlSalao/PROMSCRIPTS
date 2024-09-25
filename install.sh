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
    echo "Setting up Prometheus-Grafana-ELK directory..."
    mkdir -p prometheus-grafana-elk-docker
    cd prometheus-grafana-elk-docker || exit
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
      - targets: ['prometheus:9090']
  - job_name: 'vsat'
    static_configs:
    - targets: ['localhost:4000']
EOT
}

# Create Logstash configuration file
create_logstash_config() {
    echo "Creating Logstash configuration file (logstash.conf)..."
    cat <<EOT > logstash.conf
input {
  beats {
    port => 5044
  }
}

filter {
  grok {
    match => { "message" => "%{COMMONAPACHELOG}" }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
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

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.9.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - ELASTIC_PASSWORD=your_password_here  # Set the password for the 'elastic' user
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - elk

  logstash:
    image: docker.elastic.co/logstash/logstash:8.9.0
    container_name: logstash
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"
      - "9600:9600"
    networks:
      - elk
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.9.0
    container_name: kibana
    environment:
      - ELASTICSEARCH_USERNAME=elastic  # Username for Elasticsearch
      - ELASTICSEARCH_PASSWORD=your_password_here  # Use the same password set for Elasticsearch
    ports:
      - "5601:5601"
    networks:
      - elk
    depends_on:
      - elasticsearch

volumes:
  grafana-data:
  es-data:

networks:
  monitoring:
  elk:
EOT
}

# Start Docker Compose services
start_docker_compose() {
    echo "Starting Docker containers with Docker Compose..."
    docker-compose up -d
}

# Main execution
echo "Starting Prometheus, Grafana, and ELK Stack Docker setup..."

# Step 1: Check and install Docker if not installed
check_docker

# Step 2: Check and install Docker Compose if not installed
check_docker_compose

# Step 3: Set up the project directory
setup_directory

# Step 4: Create configuration files
create_prometheus_config
create_logstash_config
create_docker_compose_file

# Step 5: Start Docker Compose
start_docker_compose

echo "Prometheus, Grafana, and ELK Stack setup is complete!"
echo "Prometheus is running on http://localhost:9090"
echo "Grafana is running on http://localhost:30001(Default login: admin/admin)"
echo "Kibana is running on http://localhost:5601"
