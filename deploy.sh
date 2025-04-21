#!/bin/bash

# Check if the current node is part of a swarm
if docker info | grep -q "Swarm: active"; then
    echo "Node is part of a swarm. Leaving the swarm..."
    docker swarm leave --force
else
    echo "Node is not part of a swarm."
fi

# Initialize a new swarm
echo "Initializing a new Docker Swarm..."
docker swarm init

# Deploy the Docker Compose file as a stack
STACK_NAME="my_stack"
COMPOSE_FILE="docker-compose.yml"

if [ -f "$COMPOSE_FILE" ]; then
    echo "Deploying stack '$STACK_NAME' using '$COMPOSE_FILE'..."
    docker stack deploy -c "$COMPOSE_FILE" "$STACK_NAME"
else
    echo "Error: '$COMPOSE_FILE' not found. Please ensure the file exists in the current directory."
    exit 1
fi

echo "Deployment complete."