#!/bin/bash

echo "Creating Weaviate schema..."

# Wait for Weaviate to be ready
sleep 5

# Create schema
curl -X POST \
  http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "MLModel",
    "properties": [
      {
        "name": "name",
        "dataType": ["text"]
      },
      {
        "name": "version",
        "dataType": ["text"]
      },
      {
        "name": "accuracy",
        "dataType": ["number"]
      },
      {
        "name": "description",
        "dataType": ["text"]
      },
      {
        "name": "createdAt",
        "dataType": ["date"]
      }
    ]
  }'

echo ""
echo "Weaviate schema created successfully!"
