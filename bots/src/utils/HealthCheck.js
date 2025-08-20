import http from 'http';
import { config } from '../config/config.js';
import { logger } from './Logger.js';

/**
 * Health check server for monitoring bot status
 */
export class HealthCheckServer {
  constructor(bot) {
    this.bot = bot;
    this.server = null;
    this.logger = logger.child({ component: 'HealthCheckServer' });
  }

  /**
   * Start the health check server
   */
  start() {
    if (!config.healthCheck.enabled) {
      this.logger.info('Health check server disabled');
      return;
    }

    this.server = http.createServer((req, res) => {
      const url = new URL(req.url, `http://${req.headers.host}`);
      
      // Set CORS headers
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
      res.setHeader('Content-Type', 'application/json');

      // Handle OPTIONS request
      if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
      }

      // Only allow GET requests
      if (req.method !== 'GET') {
        res.writeHead(405, { 'Allow': 'GET, OPTIONS' });
        res.end(JSON.stringify({ error: 'Method not allowed' }));
        return;
      }

      try {
        switch (url.pathname) {
          case '/health':
          case '/':
            this.handleHealthCheck(res);
            break;
          case '/metrics':
            this.handleMetrics(res);
            break;
          case '/ready':
            this.handleReadiness(res);
            break;
          case '/live':
            this.handleLiveness(res);
            break;
          default:
            res.writeHead(404);
            res.end(JSON.stringify({ error: 'Not found' }));
        }
      } catch (error) {
        this.logger.error('Health check endpoint error', {
          error: error.message,
          path: url.pathname
        });
        res.writeHead(500);
        res.end(JSON.stringify({ error: 'Internal server error' }));
      }
    });

    this.server.listen(config.healthCheck.port, () => {
      this.logger.info(`Health check server started on port ${config.healthCheck.port}`);
    });

    this.server.on('error', (error) => {
      this.logger.error('Health check server error', { error: error.message });
    });
  }

  /**
   * Stop the health check server
   */
  stop() {
    if (this.server) {
      this.server.close(() => {
        this.logger.info('Health check server stopped');
      });
    }
  }

  /**
   * Handle health check endpoint
   */
  handleHealthCheck(res) {
    const health = this.bot.getHealthStatus();
    const isHealthy = health.status === 'online';
    
    res.writeHead(isHealthy ? 200 : 503);
    res.end(JSON.stringify({
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      ...health
    }));
  }

  /**
   * Handle metrics endpoint
   */
  handleMetrics(res) {
    const health = this.bot.getHealthStatus();
    const metrics = {
      timestamp: new Date().toISOString(),
      uptime_seconds: health.uptime,
      memory_usage_bytes: health.memoryUsage,
      guilds_count: health.guilds,
      users_count: health.users,
      active_interactions_count: health.activeInteractions,
      rate_limit_status: health.rateLimitStatus,
      bot_status: health.status,
      last_ready: health.lastReady
    };

    res.writeHead(200);
    res.end(JSON.stringify(metrics));
  }

  /**
   * Handle readiness probe (Kubernetes)
   */
  handleReadiness(res) {
    const health = this.bot.getHealthStatus();
    const isReady = health.status === 'online' && health.guilds > 0;
    
    res.writeHead(isReady ? 200 : 503);
    res.end(JSON.stringify({
      ready: isReady,
      timestamp: new Date().toISOString(),
      status: health.status,
      guilds: health.guilds
    }));
  }

  /**
   * Handle liveness probe (Kubernetes)
   */
  handleLiveness(res) {
    const health = this.bot.getHealthStatus();
    const isAlive = process.uptime() > 0 && health.status !== 'error';
    
    res.writeHead(isAlive ? 200 : 503);
    res.end(JSON.stringify({
      alive: isAlive,
      timestamp: new Date().toISOString(),
      uptime: health.uptime,
      status: health.status
    }));
  }
}

/**
 * Process monitoring utilities
 */
export class ProcessMonitor {
  constructor() {
    this.logger = logger.child({ component: 'ProcessMonitor' });
    this.startTime = Date.now();
    this.metrics = {
      requests: 0,
      errors: 0,
      commands: {
        register: 0,
        unregister: 0,
        mystatus: 0,
        timezone: 0
      }
    };
  }

  /**
   * Start monitoring process metrics
   */
  start() {
    // Log memory usage every 5 minutes
    setInterval(() => {
      const memUsage = process.memoryUsage();
      this.logger.info('Memory usage', {
        rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
        heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
        heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
        external: `${Math.round(memUsage.external / 1024 / 1024)}MB`
      });
    }, 5 * 60 * 1000);

    // Log CPU usage every 10 minutes
    setInterval(() => {
      const cpuUsage = process.cpuUsage();
      this.logger.info('CPU usage', {
        user: cpuUsage.user,
        system: cpuUsage.system,
        uptime: process.uptime()
      });
    }, 10 * 60 * 1000);
  }

  /**
   * Increment request counter
   */
  incrementRequests() {
    this.metrics.requests++;
  }

  /**
   * Increment error counter
   */
  incrementErrors() {
    this.metrics.errors++;
  }

  /**
   * Increment command counter
   */
  incrementCommand(command) {
    if (this.metrics.commands[command] !== undefined) {
      this.metrics.commands[command]++;
    }
  }

  /**
   * Get current metrics
   */
  getMetrics() {
    return {
      ...this.metrics,
      uptime: Date.now() - this.startTime,
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage()
    };
  }
}