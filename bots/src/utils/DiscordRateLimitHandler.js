/**
 * Discord API rate limit handler
 * Manages Discord API rate limits and provides queue-based request handling
 */
export class DiscordRateLimitHandler {
  constructor(logger, options = {}) {
    this.logger = logger;
    this.options = {
      globalRateLimit: options.globalRateLimit || 50, // Global rate limit per second
      bucketRateLimit: options.bucketRateLimit || 5, // Per-bucket rate limit
      queueTimeout: options.queueTimeout || 30000, // 30 seconds
      maxQueueSize: options.maxQueueSize || 100,
      ...options
    };

    // Rate limit tracking
    this.globalRateLimit = {
      remaining: this.options.globalRateLimit,
      resetTime: Date.now() + 1000,
      isLimited: false
    };

    // Bucket-specific rate limits
    this.buckets = new Map();
    
    // Request queue
    this.queue = [];
    this.processing = false;

    // Start queue processor
    this.startQueueProcessor();
  }

  /**
   * Execute a Discord API request with rate limit handling
   * @param {Function} requestFunction - Function that makes the Discord API request
   * @param {string} bucket - Rate limit bucket identifier
   * @param {Object} options - Request options
   * @returns {Promise<any>} Request result
   */
  async executeRequest(requestFunction, bucket = 'default', options = {}) {
    return new Promise((resolve, reject) => {
      const request = {
        id: this.generateRequestId(),
        function: requestFunction,
        bucket,
        options,
        resolve,
        reject,
        timestamp: Date.now(),
        timeout: setTimeout(() => {
          this.removeFromQueue(request.id);
          reject(new Error('Request timeout: Discord API request took too long'));
        }, this.options.queueTimeout)
      };

      // Check queue size
      if (this.queue.length >= this.options.maxQueueSize) {
        clearTimeout(request.timeout);
        reject(new Error('Request queue full: Too many pending Discord API requests'));
        return;
      }

      // Add to queue
      this.queue.push(request);
      this.logger.debug(`Discord API request queued`, {
        requestId: request.id,
        bucket,
        queueSize: this.queue.length
      });

      // Process queue if not already processing
      if (!this.processing) {
        this.processQueue();
      }
    });
  }

  /**
   * Start the queue processor
   */
  startQueueProcessor() {
    setInterval(() => {
      if (!this.processing && this.queue.length > 0) {
        this.processQueue();
      }
    }, 100); // Check every 100ms
  }

  /**
   * Process the request queue
   */
  async processQueue() {
    if (this.processing || this.queue.length === 0) {
      return;
    }

    this.processing = true;

    try {
      while (this.queue.length > 0) {
        // Check global rate limit
        if (this.isGloballyRateLimited()) {
          const waitTime = this.globalRateLimit.resetTime - Date.now();
          if (waitTime > 0) {
            this.logger.debug(`Waiting for global rate limit reset`, { waitTime });
            await this.sleep(waitTime);
          }
          this.resetGlobalRateLimit();
        }

        // Get next request
        const request = this.queue.shift();
        if (!request) break;

        // Check if request has timed out
        if (Date.now() - request.timestamp > this.options.queueTimeout) {
          clearTimeout(request.timeout);
          request.reject(new Error('Request timeout: Request expired in queue'));
          continue;
        }

        // Check bucket rate limit
        const bucket = this.getBucket(request.bucket);
        if (this.isBucketRateLimited(bucket)) {
          const waitTime = bucket.resetTime - Date.now();
          if (waitTime > 0) {
            this.logger.debug(`Waiting for bucket rate limit reset`, { 
              bucket: request.bucket, 
              waitTime 
            });
            
            // Put request back at front of queue
            this.queue.unshift(request);
            await this.sleep(waitTime);
            continue;
          }
          this.resetBucketRateLimit(bucket);
        }

        // Execute the request
        try {
          const startTime = Date.now();
          const result = await this.executeRequestWithRateLimit(request);
          const duration = Date.now() - startTime;

          clearTimeout(request.timeout);
          request.resolve(result);

          this.logger.debug(`Discord API request completed`, {
            requestId: request.id,
            bucket: request.bucket,
            duration,
            success: true
          });

        } catch (error) {
          clearTimeout(request.timeout);
          
          // Handle rate limit errors
          if (this.isRateLimitError(error)) {
            await this.handleRateLimitError(error, request);
          } else {
            request.reject(error);
            this.logger.error(`Discord API request failed`, {
              requestId: request.id,
              bucket: request.bucket,
              error: error.message
            });
          }
        }

        // Small delay between requests to prevent overwhelming
        await this.sleep(50);
      }
    } finally {
      this.processing = false;
    }
  }

  /**
   * Execute request and update rate limit information
   * @param {Object} request - Request object
   * @returns {Promise<any>} Request result
   */
  async executeRequestWithRateLimit(request) {
    const result = await request.function();

    // Update rate limit counters (this would be updated from response headers in real implementation)
    this.updateGlobalRateLimit();
    this.updateBucketRateLimit(request.bucket);

    return result;
  }

  /**
   * Handle rate limit errors
   * @param {Error} error - Rate limit error
   * @param {Object} request - Original request
   */
  async handleRateLimitError(error, request) {
    const retryAfter = this.extractRetryAfter(error);
    
    this.logger.warn(`Discord API rate limited`, {
      requestId: request.id,
      bucket: request.bucket,
      retryAfter
    });

    // Update rate limit state
    if (error.global) {
      this.globalRateLimit.isLimited = true;
      this.globalRateLimit.resetTime = Date.now() + retryAfter;
    } else {
      const bucket = this.getBucket(request.bucket);
      bucket.isLimited = true;
      bucket.resetTime = Date.now() + retryAfter;
    }

    // Put request back in queue to retry
    this.queue.unshift(request);
  }

  /**
   * Check if error is a rate limit error
   * @param {Error} error - Error to check
   * @returns {boolean} Whether error is rate limit related
   */
  isRateLimitError(error) {
    return error.status === 429 || 
           error.code === 429 || 
           error.message?.includes('rate limit') ||
           error.message?.includes('Too Many Requests');
  }

  /**
   * Extract retry-after value from rate limit error
   * @param {Error} error - Rate limit error
   * @returns {number} Retry after time in milliseconds
   */
  extractRetryAfter(error) {
    // Try to get retry-after from various possible locations
    let retryAfter = 0;

    if (error.retryAfter) {
      retryAfter = error.retryAfter * 1000;
    } else if (error.response?.headers?.['retry-after']) {
      retryAfter = parseInt(error.response.headers['retry-after']) * 1000;
    } else if (error.response?.data?.retry_after) {
      retryAfter = error.response.data.retry_after * 1000;
    } else {
      // Default fallback
      retryAfter = 1000;
    }

    return Math.max(retryAfter, 1000); // Minimum 1 second
  }

  /**
   * Check if globally rate limited
   * @returns {boolean} Whether globally rate limited
   */
  isGloballyRateLimited() {
    return this.globalRateLimit.isLimited || 
           (this.globalRateLimit.remaining <= 0 && Date.now() < this.globalRateLimit.resetTime);
  }

  /**
   * Check if bucket is rate limited
   * @param {Object} bucket - Bucket object
   * @returns {boolean} Whether bucket is rate limited
   */
  isBucketRateLimited(bucket) {
    return bucket.isLimited || 
           (bucket.remaining <= 0 && Date.now() < bucket.resetTime);
  }

  /**
   * Get or create bucket for rate limiting
   * @param {string} bucketId - Bucket identifier
   * @returns {Object} Bucket object
   */
  getBucket(bucketId) {
    if (!this.buckets.has(bucketId)) {
      this.buckets.set(bucketId, {
        id: bucketId,
        remaining: this.options.bucketRateLimit,
        resetTime: Date.now() + 1000,
        isLimited: false
      });
    }
    return this.buckets.get(bucketId);
  }

  /**
   * Update global rate limit counters
   */
  updateGlobalRateLimit() {
    this.globalRateLimit.remaining = Math.max(0, this.globalRateLimit.remaining - 1);
    
    if (this.globalRateLimit.remaining === 0) {
      this.globalRateLimit.resetTime = Date.now() + 1000;
    }
  }

  /**
   * Update bucket rate limit counters
   * @param {string} bucketId - Bucket identifier
   */
  updateBucketRateLimit(bucketId) {
    const bucket = this.getBucket(bucketId);
    bucket.remaining = Math.max(0, bucket.remaining - 1);
    
    if (bucket.remaining === 0) {
      bucket.resetTime = Date.now() + 1000;
    }
  }

  /**
   * Reset global rate limit
   */
  resetGlobalRateLimit() {
    this.globalRateLimit.remaining = this.options.globalRateLimit;
    this.globalRateLimit.resetTime = Date.now() + 1000;
    this.globalRateLimit.isLimited = false;
  }

  /**
   * Reset bucket rate limit
   * @param {Object} bucket - Bucket to reset
   */
  resetBucketRateLimit(bucket) {
    bucket.remaining = this.options.bucketRateLimit;
    bucket.resetTime = Date.now() + 1000;
    bucket.isLimited = false;
  }

  /**
   * Remove request from queue by ID
   * @param {string} requestId - Request ID to remove
   */
  removeFromQueue(requestId) {
    const index = this.queue.findIndex(req => req.id === requestId);
    if (index !== -1) {
      const request = this.queue.splice(index, 1)[0];
      clearTimeout(request.timeout);
    }
  }

  /**
   * Generate unique request ID
   * @returns {string} Unique request identifier
   */
  generateRequestId() {
    return `req_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  }

  /**
   * Sleep for specified duration
   * @param {number} ms - Milliseconds to sleep
   * @returns {Promise<void>}
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Get current rate limit status
   * @returns {Object} Rate limit status
   */
  getStatus() {
    return {
      global: {
        remaining: this.globalRateLimit.remaining,
        resetTime: this.globalRateLimit.resetTime,
        isLimited: this.globalRateLimit.isLimited
      },
      buckets: Array.from(this.buckets.entries()).map(([id, bucket]) => ({
        id,
        remaining: bucket.remaining,
        resetTime: bucket.resetTime,
        isLimited: bucket.isLimited
      })),
      queue: {
        size: this.queue.length,
        processing: this.processing
      }
    };
  }

  /**
   * Clear all rate limits (for testing)
   */
  clearRateLimits() {
    this.resetGlobalRateLimit();
    this.buckets.clear();
    this.queue.forEach(req => {
      clearTimeout(req.timeout);
      req.reject(new Error('Rate limit handler reset'));
    });
    this.queue = [];
    this.processing = false;
  }
}