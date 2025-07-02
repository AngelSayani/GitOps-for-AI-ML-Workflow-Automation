#!/bin/bash
set -e

echo "=== GitOps AI/ML Lab Complete Setup ==="
echo "Starting at: $(date)"

# Update system
echo "Updating system packages..."
yum update -y

# Install required packages
echo "Installing Docker, Git, and Python..."
yum install -y docker git python3 python3-pip jq

# Start Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker
usermod -aG docker cloud_user

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Python packages
echo "Installing Python packages..."
pip3 install dvc

# Clone the repository
echo "Cloning lab repository..."
cd /home/cloud_user
rm -rf gitops-lab
git clone https://github.com/AngelSayani/GitOps-for-AI-ML-Workflow-Automation.git gitops-lab
cd gitops-lab
chmod +x *.sh

# Set ownership
chown -R cloud_user:cloud_user /home/cloud_user/gitops-lab

# Start services as cloud_user
echo "Starting Docker services..."
sudo -u cloud_user docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Configure MinIO
echo "Configuring MinIO..."
sudo -u cloud_user docker run --rm --network host minio/mc alias set myminio http://localhost:9000 minioadmin minioadmin123
sudo -u cloud_user docker run --rm --network host minio/mc mb myminio/ml-models || true
sudo -u cloud_user docker run --rm --network host minio/mc mb myminio/ml-data || true

# Configure Weaviate
echo "Configuring Weaviate schema..."
curl -X POST http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "MLModel",
    "properties": [
      {"name": "name", "dataType": ["text"]},
      {"name": "version", "dataType": ["text"]},
      {"name": "accuracy", "dataType": ["number"]},
      {"name": "description", "dataType": ["text"]}
    ]
  }' || true

# Create verification script
cat > /home/cloud_user/gitops-lab/verify-setup.sh << 'EOF'
#!/bin/bash
echo "=== Lab Setup Verification ==="
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker-compose --version
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "MinIO status:"
curl -s -I http://localhost:9000/minio/health/live | head -1
echo ""
echo "Weaviate status:"
curl -s http://localhost:8080/v1/meta | jq -r '.version'
echo ""
echo "=== Setup Complete! ==="
EOF
chmod +x /home/cloud_user/gitops-lab/verify-setup.sh
chown cloud_user:cloud_user /home/cloud_user/gitops-lab/verify-setup.sh

# Final message
echo ""
echo "Setup completed at: $(date)"
echo ""
echo "================================================================"
echo "IMPORTANT: Now run the following command:"
echo "  sudo su - cloud_user"
echo ""
echo "Then navigate to the lab directory:"
echo "  cd ~/gitops-lab"
echo "================================================================"
