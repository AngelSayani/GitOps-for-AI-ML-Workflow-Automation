#!/bin/bash

echo "Configuring MinIO..."

# Wait for MinIO to be ready
echo "Waiting for MinIO to start..."
sleep 10

# Configure MinIO client
docker run --rm --network host \
  minio/mc alias set myminio http://localhost:9000 minioadmin minioadmin123

# Create buckets
echo "Creating ML buckets..."
docker run --rm --network host \
  minio/mc mb myminio/ml-models
docker run --rm --network host \
  minio/mc mb myminio/ml-data

echo "MinIO configuration complete!"
echo "Buckets created: ml-models, ml-data"
