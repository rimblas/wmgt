#!/bin/bash

# WMGT Discord Bot Backup Script
# This script creates backups of logs and configuration

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="wmgt-bot-backup-${TIMESTAMP}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

log_info "Creating backup: $BACKUP_NAME"

# Create backup archive
cd "$PROJECT_DIR"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
    --exclude='node_modules' \
    --exclude='backups' \
    --exclude='.git' \
    --exclude='*.log' \
    logs/ \
    src/ \
    package*.json \
    .env.production.example \
    Dockerfile \
    docker-compose.yml \
    scripts/

log_success "Backup created: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

# Clean up old backups (keep last 7)
log_info "Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t wmgt-bot-backup-*.tar.gz | tail -n +8 | xargs -r rm --

log_success "Backup completed successfully"