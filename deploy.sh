#!/bin/bash

# Function to check service health
check_service_health() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    local health_status="unhealthy"

    echo "Checking health of $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker service ls --format "{{.Name}} {{.Replicas}}" | grep -q "$service_name.*[0-9]/[0-9]"; then
            health_status="healthy"
            break
        fi
        echo "Attempt $attempt: Service $service_name not ready yet..."
        sleep 10
        attempt=$((attempt + 1))
    done

    if [ "$health_status" != "healthy" ]; then
        echo "Service $service_name failed to become healthy"
        return 1
    fi
    return 0
}

# Function to rollback deployment
rollback_deployment() {
    local stack_name=$1
    echo "Rolling back deployment..."
    docker stack rm $stack_name
    sleep 10
    exit 1
}

# Main deployment logic
STACK_NAME="my_stack"
COMPOSE_FILE="docker-compose.yml"
NETWORK_NAME="my_stack_fitmitra_network"

# Check if stack exists
if docker stack ls | grep -q "$STACK_NAME"; then
    echo "Existing stack found. Preparing for zero-downtime deployment..."
    OLD_STACK_NAME="${STACK_NAME}_old"
    
    # Rename existing stack
    echo "Renaming existing stack to $OLD_STACK_NAME..."
    docker stack deploy -c "$COMPOSE_FILE" "$OLD_STACK_NAME"
    sleep 10
fi

# Initialize swarm if not already initialized
if ! docker info | grep -q "Swarm: active"; then
    echo "Initializing Docker Swarm..."
    docker swarm init
fi

# Handle network creation
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "Creating network '$NETWORK_NAME'..."
    docker network create --driver overlay "$NETWORK_NAME"
else
    echo "Network '$NETWORK_NAME' already exists."
fi

# Deploy new stack
echo "Deploying new stack '$STACK_NAME'..."
docker stack deploy -c "$COMPOSE_FILE" "$STACK_NAME"

# Check health of new services
echo "Checking health of new services..."
if ! check_service_health "${STACK_NAME}_frontend" || ! check_service_health "${STACK_NAME}_backend"; then
    echo "New deployment failed health check"
    rollback_deployment "$STACK_NAME"
fi

# If new deployment is healthy, remove old stack
if [ -n "$OLD_STACK_NAME" ]; then
    echo "New deployment is healthy. Removing old stack..."
    docker stack rm "$OLD_STACK_NAME"
fi

echo "Deployment completed successfully!"