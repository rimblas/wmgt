/**
 * Retry handler with exponential backoff for API calls and operations
 * Provides configurable retry logic with jitter and circuit breaker patterns
 */
export class RetryHandler {
  constructor(logger, options = {}) {
    this.logger = logger;
    this.options = {
      maxRetries: options.maxRetries || 3,
      baseDelay: options.baseDelay || 1000, // 1 second
      maxDelay: options.maxDelay || 30000, // 30 seconds
      backoffMultiplier: options.backoffMultiplier || 2,
      jitter: options.jitter !== false, // Default to true
      jitterFactor: options.jitterFactor || 0.1,
      ...options
    };

    // Circuit breaker state
    this.circuitBreaker = {
      failures: 0,
      lastFailureTime: null,
      state: 'CLOSED', // CLOSED, OPEN, HALF_OPEN
      failureThreshold: options.circuitBreakerThreshold || 5,
      recoveryTimeout: options.circuitBreakerTimeout || 60000 // 1 minute
    };
  }

  /**
   * Execute operation with retry logic and exponential backoff
   * @param {Function} operation - Async operation to execute
   * @param {Object} options - Retry options for this specific operation
   * @param {string} operationName - Name of the operation for logging
   * @returns {Promise<any>} Result of the operation
   */
  async executeWithRetry(operation, options = {}, operationName = 'operation') {
    const config = { ...this.options, ...options };
    let lastError;
    let attempt = 0;

    // Check circuit breaker
    if (this.isCircuitOpen()) {
      const error = new Error(`Circuit breaker is OPEN for ${operationName}`);
      error.circuitBreakerOpen = true;
      throw error;
    }

    while (attempt <= config.maxRetries) {
      try {
        const startTime = Date.now();
        
        // Execute the operation
        const result = await operation();
        
        // Log successful execution
        const duration = Date.now() - startTime;
        this.logger.performance(operationName, duration, { 
          attempt: attempt + 1,
          success: true 
        });

        // Reset circuit breaker on success
        this.resetCircuitBreaker();
        
        return result;

      } catch (error) {
        lastError = error;
        attempt++;

        // Log the error
        this.logger.error(`${operationName} failed on attempt ${attempt}`, {
          error: error.message,
          attempt,
          maxRetries: config.maxRetries,
          operationName
        });

        // Update circuit breaker
        this.recordFailure();

        // Check if we should retry
        if (!this.shouldRetry(error, attempt, config)) {
          break;
        }

        // Calculate delay for next attempt
        const delay = this.calculateDelay(attempt - 1, config, error);
        
        // Log retry attempt
        this.logger.retryAttempt(operationName, attempt, config.maxRetries, delay, {
          errorType: error.constructor.name,
          errorMessage: error.message
        });

        // Wait before retrying
        await this.sleep(delay);
      }
    }

    // All retries exhausted
    this.logger.error(`${operationName} failed after ${attempt} attempts`, {
      finalError: lastError.message,
      totalAttempts: attempt,
      operationName
    });

    throw lastError;
  }

  /**
   * Determine if an error should be retried
   * @param {Error} error - The error that occurred
   * @param {number} attempt - Current attempt number
   * @param {Object} config - Retry configuration
   * @returns {boolean} Whether to retry
   */
  shouldRetry(error, attempt, config) {
    // Don't retry if we've exceeded max attempts
    if (attempt > config.maxRetries) {
      return false;
    }

    // Don't retry if circuit breaker is open
    if (this.isCircuitOpen()) {
      return false;
    }

    // Check for specific error conditions that shouldn't be retried
    if (error.noRetry || error.code === 'ABORT') {
      return false;
    }

    // Don't retry client errors (4xx) except for rate limiting (429)
    if (error.response?.status >= 400 && error.response?.status < 500) {
      return error.response.status === 429; // Only retry rate limits
    }

    // Retry server errors (5xx)
    if (error.response?.status >= 500) {
      return true;
    }

    // Retry network errors
    const networkErrors = ['ECONNREFUSED', 'ENOTFOUND', 'ECONNRESET', 'ETIMEDOUT', 'ENETUNREACH'];
    if (error.code && networkErrors.includes(error.code)) {
      return true;
    }

    // Retry timeout errors
    if (error.name === 'TimeoutError' || error.message?.includes('timeout')) {
      return true;
    }

    // Don't retry validation or business logic errors by default
    const nonRetryableErrors = [
      'ValidationError',
      'AuthenticationError',
      'AuthorizationError',
      'NotFoundError'
    ];
    
    if (nonRetryableErrors.includes(error.name)) {
      return false;
    }

    // Default to retrying unknown errors
    return true;
  }

  /**
   * Calculate delay for next retry attempt with exponential backoff and jitter
   * @param {number} attempt - Current attempt number (0-based)
   * @param {Object} config - Retry configuration
   * @param {Error} error - The error that occurred (for rate limit handling)
   * @returns {number} Delay in milliseconds
   */
  calculateDelay(attempt, config, error) {
    // Check for rate limit headers first
    if (error.response?.headers) {
      const retryAfter = error.response.headers['retry-after'];
      if (retryAfter) {
        const delay = parseInt(retryAfter) * 1000;
        return Math.min(delay, config.maxDelay);
      }

      const rateLimitReset = error.response.headers['x-ratelimit-reset'];
      if (rateLimitReset) {
        const resetTime = parseInt(rateLimitReset) * 1000;
        const delay = Math.max(0, resetTime - Date.now());
        return Math.min(delay, config.maxDelay);
      }
    }

    // Calculate exponential backoff delay
    let delay = config.baseDelay * Math.pow(config.backoffMultiplier, attempt);
    
    // Apply maximum delay limit
    delay = Math.min(delay, config.maxDelay);

    // Add jitter to prevent thundering herd
    if (config.jitter) {
      const jitterAmount = delay * config.jitterFactor;
      const jitterOffset = (Math.random() - 0.5) * 2 * jitterAmount;
      delay = Math.max(0, delay + jitterOffset);
    }

    return Math.round(delay);
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
   * Check if circuit breaker is open
   * @returns {boolean} Whether circuit breaker is open
   */
  isCircuitOpen() {
    if (this.circuitBreaker.state === 'CLOSED') {
      return false;
    }

    if (this.circuitBreaker.state === 'OPEN') {
      // Check if recovery timeout has passed
      const timeSinceLastFailure = Date.now() - this.circuitBreaker.lastFailureTime;
      if (timeSinceLastFailure >= this.circuitBreaker.recoveryTimeout) {
        this.circuitBreaker.state = 'HALF_OPEN';
        this.logger.info('Circuit breaker transitioning to HALF_OPEN state');
        return false;
      }
      return true;
    }

    // HALF_OPEN state - allow one request through
    return false;
  }

  /**
   * Record a failure for circuit breaker
   */
  recordFailure() {
    this.circuitBreaker.failures++;
    this.circuitBreaker.lastFailureTime = Date.now();

    if (this.circuitBreaker.failures >= this.circuitBreaker.failureThreshold) {
      this.circuitBreaker.state = 'OPEN';
      this.logger.warn(`Circuit breaker opened after ${this.circuitBreaker.failures} failures`);
    }
  }

  /**
   * Reset circuit breaker on successful operation
   */
  resetCircuitBreaker() {
    if (this.circuitBreaker.state !== 'CLOSED') {
      this.logger.info('Circuit breaker reset to CLOSED state');
    }
    
    this.circuitBreaker.failures = 0;
    this.circuitBreaker.lastFailureTime = null;
    this.circuitBreaker.state = 'CLOSED';
  }

  /**
   * Get circuit breaker status
   * @returns {Object} Circuit breaker status
   */
  getCircuitBreakerStatus() {
    return {
      state: this.circuitBreaker.state,
      failures: this.circuitBreaker.failures,
      lastFailureTime: this.circuitBreaker.lastFailureTime,
      isOpen: this.isCircuitOpen()
    };
  }

  /**
   * Create a wrapper function that automatically retries
   * @param {Function} operation - Operation to wrap
   * @param {Object} options - Retry options
   * @param {string} operationName - Name for logging
   * @returns {Function} Wrapped function with retry logic
   */
  wrap(operation, options = {}, operationName = 'wrapped_operation') {
    return async (...args) => {
      return this.executeWithRetry(
        () => operation(...args),
        options,
        operationName
      );
    };
  }

  /**
   * Create a retry handler for API calls specifically
   * @param {Object} apiClient - Axios or similar API client
   * @param {Object} options - Retry options
   * @returns {RetryHandler} Configured retry handler for API calls
   */
  static forApiCalls(logger, options = {}) {
    return new RetryHandler(logger, {
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 10000,
      backoffMultiplier: 2,
      jitter: true,
      circuitBreakerThreshold: 5,
      circuitBreakerTimeout: 30000,
      ...options
    });
  }

  /**
   * Create a retry handler for Discord API calls
   * @param {Object} options - Retry options
   * @returns {RetryHandler} Configured retry handler for Discord API
   */
  static forDiscordApi(logger, options = {}) {
    return new RetryHandler(logger, {
      maxRetries: 2, // Discord has its own retry logic
      baseDelay: 500,
      maxDelay: 5000,
      backoffMultiplier: 2,
      jitter: true,
      circuitBreakerThreshold: 10,
      circuitBreakerTimeout: 60000,
      ...options
    });
  }
}