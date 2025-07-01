#!/bin/bash

echo "=== GitOps AI/ML Lab Setup Script ==="
echo "Installing Docker..."

# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker cloud_user

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install git if missing
sudo yum install -y git

# Install Python tools
echo "Installing Python tools..."
sudo yum install -y python3 python3-pip
sudo pip3 install dvc

echo ""
echo "=== Setup Complete! ==="
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version
echo ""
echo "IMPORTANT: You need to log out and back in for Docker group changes to take effect!"
echo "Run: exit"
echo "Then SSH back in with the same credentials."
