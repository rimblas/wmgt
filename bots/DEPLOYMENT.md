# WMGT Discord Bot - Production Deployment Guide

This guide covers the deployment of the WMGT Discord Tournament Registration Bot to production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Docker Deployment](#docker-deployment)
4. [Docker Compose Deployment](#docker-compose-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Monitoring and Health Checks](#monitoring-and-health-checks)
7. [Backup and Recovery](#backup-and-recovery)
8. [Troubleshooting](#troubleshooting)
9. [Security Considerations](#security-considerations)

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended) or macOS
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Memory**: Minimum 512MB RAM allocated to container
- **CPU**: Minimum 0.25 CPU cores
- **Storage**: 1GB free space for logs and backups
- **Network**: Outbound HTTPS access to Discord API and your backend API

### Required Accounts and Tokens

1. **Discord Bot Token**: Create a bot application at https://discord.com/developers/applications
2. **Discord Client ID**: From your Discord application
3. **Discord Guild ID**: Your Discord server ID (optional for global commands)
4. **Backend API Access**: Ensure your API endpoints are accessible

## Environment Setup

### 1. Clone and Prepare the Project

```bash
# Clone the repository
git clone <your-repo-url>
cd wmgt/bots

# Create production environment file
cp .env.production.example .env.production
```

### 2. Configure Environment Variables

Edit `.env.production` with your production values:

```bash
# Discord Bot Configuration
DISCORD_BOT_TOKEN=your_production_bot_token_here
DISCORD_CLIENT_ID=your_discord_client_id_here
DISCORD_GUILD_ID=your_production_guild_id_here

# API Configuration
API_BASE_URL=https://your-production-api.com/ords/wmgt

# Environment
NODE_ENV=production

# Logging Configuration
LOG_LEVEL=info
LOG_FILE_PATH=/app/logs/bot.log
LOG_MAX_FILES=7
LOG_MAX_SIZE=10m

# Health Check Configuration
HEALTH_CHECK_PORT=3000
HEALTH_CHECK_ENABLED=true

# Performance Configuration
MAX_CONCURRENT_REQUESTS=10
REQUEST_TIMEOUT=30000
RETRY_ATTEMPTS=3
RETRY_DELAY=1000

# Security Configuration
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. Secure the Environment File

```bash
# Set appropriate permissions
chmod 600 .env.production

# Ensure it's not tracked by git
echo ".env.production" >> .gitignore
```

## Docker Deployment

### Method 1: Using Deployment Script (Recommended)

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Deploy the bot
./scripts/deploy.sh deploy

# Check deployment status
./scripts/deploy.sh status

# View logs
./scripts/deploy.sh logs
```

### Method 2: Manual Docker Commands

```bash
# Build the image
docker build -t wmgt-discord-bot:latest .

# Create network
docker network create bot-network

# Run the container
docker run -d \
  --name wmgt-discord-bot \
  --network bot-network \
  --env-file .env.production \
  --volume $(pwd)/logs:/app/logs \
  --publish 3000:3000 \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  wmgt-discord-bot:latest
```

## Docker Compose Deployment

### 1. Deploy with Docker Compose

```bash
# Deploy using docker-compose
./scripts/deploy.sh compose

# Or manually:
docker-compose up -d
```

### 2. Manage the Deployment

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Update and restart
docker-compose pull
docker-compose up -d
```

## Kubernetes Deployment

### 1. Create Kubernetes Manifests

Create `k8s/namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wmgt-bot
```

Create `k8s/secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bot-secrets
  namespace: wmgt-bot
type: Opaque
stringData:
  DISCORD_BOT_TOKEN: "your_token_here"
  DISCORD_CLIENT_ID: "your_client_id_here"
  API_BASE_URL: "https://your-api.com/ords/wmgt"
```

Create `k8s/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wmgt-discord-bot
  namespace: wmgt-bot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wmgt-discord-bot
  template:
    metadata:
      labels:
        app: wmgt-discord-bot
    spec:
      containers:
      - name: bot
        image: wmgt-discord-bot:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: HEALTH_CHECK_ENABLED
          value: "true"
        envFrom:
        - secretRef:
            name: bot-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /live
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        volumeMounts:
        - name: logs
          mountPath: /app/logs
      volumes:
      - name: logs
        emptyDir: {}
```

Create `k8s/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: wmgt-discord-bot-service
  namespace: wmgt-bot
spec:
  selector:
    app: wmgt-discord-bot
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

### 2. Deploy to Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n wmgt-bot

# View logs
kubectl logs -f deployment/wmgt-discord-bot -n wmgt-bot
```

## Monitoring and Health Checks

### Health Check Endpoints

The bot exposes several health check endpoints on port 3000:

- `GET /health` - Overall health status
- `GET /ready` - Readiness probe (Kubernetes)
- `GET /live` - Liveness probe (Kubernetes)
- `GET /metrics` - Prometheus-style metrics

### Example Health Check Response

```json
{
  "status": "healthy",
  "timestamp": "2024-08-17T10:30:00.000Z",
  "uptime": 3600,
  "memoryUsage": {
    "rss": 67108864,
    "heapUsed": 45088768,
    "heapTotal": 54525952,
    "external": 2097152
  },
  "guilds": 1,
  "users": 150,
  "activeInteractions": 0,
  "rateLimitStatus": {
    "requests": 45,
    "remaining": 955,
    "resetTime": "2024-08-17T10:31:00.000Z"
  },
  "lastReady": "2024-08-17T09:30:00.000Z"
}
```

### Monitoring Script

Use the provided monitoring script for continuous health monitoring:

```bash
# Start continuous monitoring
./scripts/monitor.sh monitor

# Check status once
./scripts/monitor.sh check

# Restart if needed
./scripts/monitor.sh restart
```

### Integration with Monitoring Systems

#### Prometheus Monitoring

Add to your `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'wmgt-discord-bot'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

#### Grafana Dashboard

Create alerts for:
- Bot offline status
- High memory usage (>400MB)
- High error rate (>5% of requests)
- Discord API rate limiting

## Backup and Recovery

### Automated Backups

```bash
# Create backup
./scripts/backup.sh

# Schedule daily backups (add to crontab)
0 2 * * * /path/to/wmgt/bots/scripts/backup.sh
```

### Manual Backup

```bash
# Backup logs and configuration
tar -czf wmgt-bot-backup-$(date +%Y%m%d).tar.gz \
  logs/ \
  .env.production \
  docker-compose.yml
```

### Recovery Process

1. **Stop the current deployment**:
   ```bash
   ./scripts/deploy.sh stop
   ```

2. **Restore from backup**:
   ```bash
   tar -xzf wmgt-bot-backup-YYYYMMDD.tar.gz
   ```

3. **Redeploy**:
   ```bash
   ./scripts/deploy.sh deploy
   ```

## Troubleshooting

### Common Issues

#### Bot Not Starting

1. **Check environment variables**:
   ```bash
   docker logs wmgt-discord-bot
   ```

2. **Verify Discord token**:
   - Ensure token is valid and not expired
   - Check bot permissions in Discord Developer Portal

3. **Check API connectivity**:
   ```bash
   curl -I https://your-api.com/ords/wmgt/tournament/current_tournament
   ```

#### High Memory Usage

1. **Check memory metrics**:
   ```bash
   curl http://localhost:3000/metrics
   ```

2. **Restart container**:
   ```bash
   ./scripts/deploy.sh restart
   ```

3. **Increase memory limits** in docker-compose.yml or Kubernetes deployment

#### Discord API Rate Limiting

1. **Check rate limit status**:
   ```bash
   curl http://localhost:3000/health | jq '.rateLimitStatus'
   ```

2. **Review bot usage patterns**
3. **Implement additional rate limiting if needed**

### Log Analysis

```bash
# View recent logs
docker logs --tail 100 wmgt-discord-bot

# Follow logs in real-time
docker logs -f wmgt-discord-bot

# Search for errors
docker logs wmgt-discord-bot 2>&1 | grep ERROR

# Export logs for analysis
docker logs wmgt-discord-bot > bot-logs-$(date +%Y%m%d).log
```

### Performance Tuning

#### Memory Optimization

```bash
# Set Node.js memory limits
NODE_OPTIONS="--max-old-space-size=400" npm start
```

#### CPU Optimization

```bash
# Limit CPU usage in Docker
docker update --cpus="0.5" wmgt-discord-bot
```

## Security Considerations

### Environment Security

1. **Secure environment files**:
   ```bash
   chmod 600 .env.production
   chown root:root .env.production
   ```

2. **Use secrets management**:
   - Kubernetes Secrets
   - Docker Secrets
   - HashiCorp Vault
   - AWS Secrets Manager

### Network Security

1. **Firewall configuration**:
   ```bash
   # Allow only necessary ports
   ufw allow 3000/tcp  # Health checks only
   ufw deny 22/tcp     # Disable SSH if not needed
   ```

2. **Use HTTPS for all API calls**
3. **Implement API authentication**

### Container Security

1. **Run as non-root user** (already configured in Dockerfile)
2. **Use minimal base images**
3. **Regular security updates**:
   ```bash
   # Update base image
   docker pull node:18-alpine
   ./scripts/deploy.sh build
   ```

### Monitoring Security

1. **Secure health check endpoints**
2. **Monitor for suspicious activity**
3. **Set up alerts for security events**

## Maintenance

### Regular Tasks

1. **Weekly**:
   - Review logs for errors
   - Check memory and CPU usage
   - Verify health check status

2. **Monthly**:
   - Update dependencies
   - Review and rotate logs
   - Test backup and recovery procedures

3. **Quarterly**:
   - Security audit
   - Performance review
   - Update documentation

### Updates and Upgrades

1. **Update bot code**:
   ```bash
   git pull origin main
   ./scripts/deploy.sh deploy
   ```

2. **Update dependencies**:
   ```bash
   npm update
   ./scripts/deploy.sh build
   ./scripts/deploy.sh restart
   ```

3. **Update Docker base image**:
   ```bash
   docker pull node:18-alpine
   ./scripts/deploy.sh build
   ```

## Support and Contacts

- **Development Team**: [Your team contact]
- **Infrastructure Team**: [Infrastructure contact]
- **Emergency Contact**: [Emergency contact]
- **Documentation**: [Link to additional docs]

---

For additional support or questions about deployment, please contact the development team or refer to the project's issue tracker.