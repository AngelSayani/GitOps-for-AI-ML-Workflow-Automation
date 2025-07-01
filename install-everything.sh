#!/bin/bash

echo "=== Complete GitOps AI/ML Lab Setup ==="

# Install Docker
echo "Installing Docker..."
sudo yum update -y
sudo yum install -y docker git python3 python3-pip
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker cloud_user

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Python packages
echo "Installing Python packages..."
sudo pip3 install dvc

# Start services
echo "Starting Docker services..."
sudo -u cloud_user docker-compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 15

# Configure MinIO
echo "Configuring MinIO..."
sudo -u cloud_user ./configure-minio.sh

# Configure Weaviate
echo "Configuring Weaviate..."
sudo -u cloud_user ./weaviate-schema.sh

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Services running:"
sudo -u cloud_user docker-compose ps
echo ""
echo "IMPORTANT: Exit and SSH back in for Docker permissions to work properly!"
echo "After logging back in, run: docker ps"
