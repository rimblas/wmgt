#!/bin/bash

# WMGT Discord Bot Deployment Script
# This script handles the deployment of the Discord bot to production

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="wmgt-discord-bot"
CONTAINER_NAME="wmgt-discord-bot"
NETWORK_NAME="bot-network"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required files exist
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ ! -f "$PROJECT_DIR/.env.production" ]; then
        log_error ".env.production file not found. Please create it from .env.production.example"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
        log_error "Dockerfile not found"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        log_error "docker-compose.yml not found"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Function to build the Docker image
build_image() {
    log_info "Building Docker image..."
    
    cd "$PROJECT_DIR"
    
    # Build the image with build args
    docker build \
        --tag "$IMAGE_NAME:latest" \
        --tag "$IMAGE_NAME:$(date +%Y%m%d-%H%M%S)" \
        --build-arg NODE_ENV=production \
        .
    
    log_success "Docker image built successfully"
}

# Function to stop existing container
stop_existing() {
    log_info "Stopping existing container if running..."
    
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Stopping existing container..."
        docker stop "$CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
        log_success "Existing container stopped and removed"
    else
        log_info "No existing container found"
    fi
}

# Function to create network if it doesn't exist
create_network() {
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        log_info "Creating Docker network: $NETWORK_NAME"
        docker network create "$NETWORK_NAME"
        log_success "Network created"
    else
        log_info "Network $NETWORK_NAME already exists"
    fi
}

# Function to deploy using docker-compose
deploy_compose() {
    log_info "Deploying with docker-compose..."
    
    cd "$PROJECT_DIR"
    
    # Pull any updated base images
    docker-compose pull
    
    # Start the services
    docker-compose up -d
    
    log_success "Services started with docker-compose"
}

# Function to deploy using docker run (alternative)
deploy_docker() {
    log_info "Deploying with docker run..."
    
    cd "$PROJECT_DIR"
    
    # Create logs directory if it doesn't exist
    mkdir -p logs
    
    # Run the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --network "$NETWORK_NAME" \
        --env-file .env.production \
        --volume "$(pwd)/logs:/app/logs" \
        --publish "3000:3000" \
        --restart unless-stopped \
        --memory="512m" \
        --cpus="0.5" \
        "$IMAGE_NAME:latest"
    
    log_success "Container deployed successfully"
}

# Function to check deployment health
check_health() {
    log_info "Checking deployment health..."
    
    # Wait a moment for the container to start
    sleep 10
    
    # Check if container is running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_success "Container is running"
        
        # Check health endpoint if available
        if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
            log_success "Health check endpoint responding"
        else
            log_warning "Health check endpoint not responding (this may be normal during startup)"
        fi
        
        # Show container logs
        log_info "Recent container logs:"
        docker logs --tail 20 "$CONTAINER_NAME"
        
    else
        log_error "Container is not running"
        log_info "Container logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    log_info "Deployment Status:"
    echo "===================="
    
    # Container status
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        echo "Container Status: Running"
        echo "Container ID: $(docker ps -q -f name="$CONTAINER_NAME")"
        echo "Image: $(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME")"
        echo "Started: $(docker inspect --format='{{.State.StartedAt}}' "$CONTAINER_NAME")"
    else
        echo "Container Status: Not Running"
    fi
    
    # Network status
    if docker network ls | grep -q "$NETWORK_NAME"; then
        echo "Network: $NETWORK_NAME (exists)"
    else
        echo "Network: $NETWORK_NAME (not found)"
    fi
    
    # Health check
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo "Health Check: Passing"
        echo "Health URL: http://localhost:3000/health"
    else
        echo "Health Check: Not responding"
    fi
    
    echo "===================="
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  build       Build the Docker image"
    echo "  deploy      Deploy the bot (build + run)"
    echo "  compose     Deploy using docker-compose"
    echo "  stop        Stop the running container"
    echo "  restart     Restart the container"
    echo "  status      Show deployment status"
    echo "  logs        Show container logs"
    echo "  health      Check health status"
    echo ""
    echo "Options:"
    echo "  -h, --help  Show this help message"
    echo "  -v          Verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 deploy           # Build and deploy the bot"
    echo "  $0 compose          # Deploy using docker-compose"
    echo "  $0 status           # Check deployment status"
    echo "  $0 logs             # View container logs"
}

# Parse command line arguments
VERBOSE=false
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        build|deploy|compose|stop|restart|status|logs|health)
            COMMAND=$1
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Enable verbose output if requested
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Main execution
case $COMMAND in
    build)
        check_prerequisites
        build_image
        ;;
    deploy)
        check_prerequisites
        build_image
        stop_existing
        create_network
        deploy_docker
        check_health
        show_status
        ;;
    compose)
        check_prerequisites
        deploy_compose
        check_health
        show_status
        ;;
    stop)
        stop_existing
        ;;
    restart)
        stop_existing
        create_network
        deploy_docker
        check_health
        ;;
    status)
        show_status
        ;;
    logs)
        if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
            docker logs -f "$CONTAINER_NAME"
        else
            log_error "Container $CONTAINER_NAME is not running"
            exit 1
        fi
        ;;
    health)
        if curl -f -s http://localhost:3000/health; then
            log_success "Health check passed"
        else
            log_error "Health check failed"
            exit 1
        fi
        ;;
    "")
        log_error "No command specified"
        show_usage
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

log_success "Script completed successfully"