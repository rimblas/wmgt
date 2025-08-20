# WMGT Discord Bot - Production Operations

## Quick Start

### Deploy to Production

```bash
# 1. Configure environment
cp .env.production.example .env.production
# Edit .env.production with your values

# 2. Deploy using Docker Compose (recommended)
npm run deploy:compose

# 3. Check status
npm run status

# 4. View logs
npm run logs
```

### Health Monitoring

```bash
# Check health status
npm run health

# Start continuous monitoring
npm run monitor

# View metrics
curl http://localhost:3000/metrics
```

## Production Checklist

### Pre-Deployment

- [ ] Environment variables configured in `.env.production`
- [ ] Discord bot token is valid and has required permissions
- [ ] Backend API is accessible and responding
- [ ] Docker and Docker Compose are installed
- [ ] Firewall rules allow necessary ports (3000 for health checks)
- [ ] Log directory has appropriate permissions
- [ ] Backup strategy is in place

### Post-Deployment

- [ ] Bot is online in Discord server
- [ ] Health check endpoint is responding (`/health`)
- [ ] Commands are registered and working (`/register`, `/unregister`, etc.)
- [ ] Logs are being written to expected location
- [ ] Monitoring is active and alerting is configured
- [ ] Backup script is scheduled

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DISCORD_BOT_TOKEN` | Discord bot token | `MTExMDMyNzc...` |
| `DISCORD_CLIENT_ID` | Discord application client ID | `1110327724129652826` |
| `API_BASE_URL` | Backend API base URL | `https://api.example.com/ords/wmgt` |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `DISCORD_GUILD_ID` | - | Guild ID for guild-specific commands |
| `LOG_LEVEL` | `info` | Logging level (error, warn, info, debug) |
| `HEALTH_CHECK_ENABLED` | `false` | Enable health check server |
| `HEALTH_CHECK_PORT` | `3000` | Health check server port |
| `MAX_CONCURRENT_REQUESTS` | `10` | Max concurrent API requests |
| `REQUEST_TIMEOUT` | `30000` | API request timeout (ms) |
| `RETRY_ATTEMPTS` | `3` | Number of retry attempts |
| `RATE_LIMIT_WINDOW` | `60000` | Rate limit window (ms) |
| `RATE_LIMIT_MAX_REQUESTS` | `100` | Max requests per window |

## Monitoring and Alerting

### Health Check Endpoints

- `GET /health` - Overall health status
- `GET /ready` - Readiness check (for Kubernetes)
- `GET /live` - Liveness check (for Kubernetes)
- `GET /metrics` - Prometheus metrics

### Key Metrics to Monitor

- **Bot Status**: Online/Offline
- **Memory Usage**: Should stay under 400MB
- **Active Interactions**: Number of ongoing Discord interactions
- **API Response Times**: Should be under 5 seconds
- **Error Rate**: Should be under 5%
- **Discord Rate Limits**: Monitor remaining quota

### Recommended Alerts

1. **Bot Offline**: Alert if health check fails for 2+ minutes
2. **High Memory**: Alert if memory usage > 400MB for 5+ minutes
3. **High Error Rate**: Alert if error rate > 10% over 5 minutes
4. **API Failures**: Alert if API calls fail for 3+ consecutive attempts
5. **Rate Limiting**: Alert if Discord rate limits are hit

## Backup and Recovery

### Automated Backups

```bash
# Schedule daily backups (add to crontab)
0 2 * * * /path/to/wmgt/bots/scripts/backup.sh
```

### Manual Backup

```bash
npm run backup
```

### Recovery Process

1. Stop current deployment: `npm run deploy:compose down`
2. Restore configuration and logs from backup
3. Redeploy: `npm run deploy:compose`
4. Verify functionality: `npm run health`

## Troubleshooting

### Common Issues

#### Bot Not Responding to Commands

1. Check if bot is online: `npm run status`
2. Verify Discord permissions in server
3. Check command registration: Look for "Successfully reloaded X commands" in logs
4. Test health endpoint: `npm run health`

#### High Memory Usage

1. Check current usage: `curl http://localhost:3000/metrics`
2. Restart container: `docker-compose restart`
3. Review logs for memory leaks: `npm run logs | grep -i memory`

#### API Connection Issues

1. Test API connectivity: `curl -I $API_BASE_URL/tournament/current_tournament`
2. Check network connectivity from container
3. Verify API credentials and endpoints
4. Review retry logic in logs

### Log Analysis

```bash
# View recent logs
npm run logs

# Search for errors
docker logs wmgt-discord-bot 2>&1 | grep ERROR

# Monitor in real-time
docker logs -f wmgt-discord-bot

# Export logs for analysis
docker logs wmgt-discord-bot > bot-logs-$(date +%Y%m%d).log
```

## Security

### Best Practices

1. **Environment Security**:
   - Keep `.env.production` secure (chmod 600)
   - Use secrets management in production
   - Rotate tokens regularly

2. **Network Security**:
   - Use HTTPS for all API calls
   - Restrict health check port access
   - Implement proper firewall rules

3. **Container Security**:
   - Run as non-root user (configured)
   - Use minimal base images
   - Regular security updates

### Security Monitoring

- Monitor for unusual API usage patterns
- Alert on authentication failures
- Track rate limiting events
- Monitor for privilege escalation attempts

## Performance Tuning

### Memory Optimization

```bash
# Set Node.js memory limits
NODE_OPTIONS="--max-old-space-size=400" npm start
```

### CPU Optimization

```bash
# Limit CPU usage in Docker Compose
# Add to docker-compose.yml:
deploy:
  resources:
    limits:
      cpus: '0.5'
```

### Database Connection Pooling

If using direct database connections:
- Configure connection pooling
- Set appropriate timeout values
- Monitor connection usage

## Scaling Considerations

### Horizontal Scaling

- Discord bots typically run as single instances
- Use sharding for very large Discord servers (10,000+ members)
- Consider load balancing for API calls

### Vertical Scaling

- Monitor memory and CPU usage
- Increase container resources as needed
- Consider SSD storage for better I/O performance

## Maintenance Schedule

### Daily

- [ ] Check bot status and health metrics
- [ ] Review error logs
- [ ] Verify backup completion

### Weekly

- [ ] Review performance metrics
- [ ] Check for security updates
- [ ] Test disaster recovery procedures

### Monthly

- [ ] Update dependencies
- [ ] Review and rotate logs
- [ ] Performance optimization review
- [ ] Security audit

### Quarterly

- [ ] Full system backup and restore test
- [ ] Capacity planning review
- [ ] Documentation updates
- [ ] Security penetration testing

## Support Contacts

- **Primary On-Call**: [Contact information]
- **Secondary On-Call**: [Contact information]
- **Development Team**: [Contact information]
- **Infrastructure Team**: [Contact information]

## Emergency Procedures

### Bot Completely Down

1. Check container status: `docker ps`
2. Check logs: `npm run logs`
3. Restart: `docker-compose restart`
4. If still down, redeploy: `npm run deploy:compose`
5. Escalate if issue persists > 15 minutes

### High Error Rate

1. Check API status
2. Review recent deployments
3. Check Discord API status
4. Consider rolling back if recent deployment
5. Implement circuit breaker if API issues

### Security Incident

1. Immediately rotate Discord bot token
2. Check logs for suspicious activity
3. Review API access logs
4. Update security credentials
5. Document incident and response

---

For detailed deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md)