#!/bin/bash

# WMGT Discord Bot Monitoring Script
# This script monitors the bot and can restart it if needed

set -e

CONTAINER_NAME="wmgt-discord-bot"
HEALTH_URL="http://localhost:3000/health"
LOG_FILE="/var/log/wmgt-bot-monitor.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_info() {
    log_message "[INFO] $1"
}

log_warning() {
    log_message "[WARNING] $1"
}

log_error() {
    log_message "[ERROR] $1"
}

# Check if container is running
check_container() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        return 0
    else
        return 1
    fi
}

# Check health endpoint
check_health() {
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Restart container
restart_container() {
    log_warning "Attempting to restart container..."
    
    # Stop container if running
    if check_container; then
        docker stop "$CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
    fi
    
    # Start container using docker-compose
    cd "$(dirname "$(dirname "$0")")"
    docker-compose up -d
    
    # Wait for startup
    sleep 30
    
    if check_container && check_health; then
        log_info "Container restarted successfully"
        return 0
    else
        log_error "Failed to restart container"
        return 1
    fi
}

# Send alert (customize this for your notification system)
send_alert() {
    local message="$1"
    log_error "ALERT: $message"
    
    # Example: Send to webhook, email, etc.
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"text\":\"WMGT Bot Alert: $message\"}" \
    #     "$SLACK_WEBHOOK_URL"
}

# Main monitoring loop
monitor() {
    log_info "Starting bot monitoring..."
    
    local failure_count=0
    local max_failures=3
    
    while true; do
        if check_container; then
            if check_health; then
                if [ $failure_count -gt 0 ]; then
                    log_info "Bot recovered after $failure_count failures"
                    failure_count=0
                fi
            else
                failure_count=$((failure_count + 1))
                log_warning "Health check failed (attempt $failure_count/$max_failures)"
                
                if [ $failure_count -ge $max_failures ]; then
                    send_alert "Bot health check failing, attempting restart"
                    if restart_container; then
                        failure_count=0
                    else
                        send_alert "Failed to restart bot container"
                    fi
                fi
            fi
        else
            failure_count=$((failure_count + 1))
            log_warning "Container not running (attempt $failure_count/$max_failures)"
            
            if [ $failure_count -ge $max_failures ]; then
                send_alert "Bot container not running, attempting restart"
                if restart_container; then
                    failure_count=0
                else
                    send_alert "Failed to restart bot container"
                fi
            fi
        fi
        
        sleep 60  # Check every minute
    done
}

# Handle command line arguments
case "${1:-monitor}" in
    monitor)
        monitor
        ;;
    check)
        if check_container && check_health; then
            echo -e "${GREEN}Bot is healthy${NC}"
            exit 0
        else
            echo -e "${RED}Bot is not healthy${NC}"
            exit 1
        fi
        ;;
    restart)
        restart_container
        ;;
    *)
        echo "Usage: $0 [monitor|check|restart]"
        echo "  monitor  - Start continuous monitoring (default)"
        echo "  check    - Check current status once"
        echo "  restart  - Restart the bot container"
        exit 1
        ;;
esac