/**
 * Example demonstrating comprehensive error handling usage
 * This file shows how to use the error handling, retry, and logging systems
 */

import { Logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { RetryHandler } from '../utils/RetryHandler.js';
import { DiscordRateLimitHandler } from '../utils/DiscordRateLimitHandler.js';

// Initialize logging
const logger = new Logger({
  level: 'debug',
  console: true,
  file: './logs/example.log'
});

// Initialize error handler
const errorHandler = new ErrorHandler(logger);

// Initialize retry handler
const retryHandler = RetryHandler.forApiCalls(logger);

// Initialize Discord rate limit handler
const discordRateLimit = new DiscordRateLimitHandler(logger);

/**
 * Example 1: Basic error handling and classification
 */
async function exampleBasicErrorHandling() {
  logger.info('=== Basic Error Handling Example ===');
  
  try {
    // Simulate an API error
    const error = new Error('Registration closed');
    error.response = {
      status: 400,
      data: { error_code: 'REGISTRATION_CLOSED' }
    };
    
    throw error;
  } catch (error) {
    // Handle the error
    const errorResponse = errorHandler.handleError(error, 'example_operation', {
      userId: '123456',
      operation: 'register_player'
    });
    
    logger.info('Error handled', {
      errorId: errorResponse.errorId,
      errorType: errorResponse.errorType,
      shouldRetry: errorResponse.shouldRetry
    });
    
    // The embed can be sent to Discord
    console.log('Error embed title:', errorResponse.embed.data.title);
    console.log('Error embed description:', errorResponse.embed.data.description);
  }
}

/**
 * Example 2: Retry logic with exponential backoff
 */
async function exampleRetryLogic() {
  logger.info('=== Retry Logic Example ===');
  
  let attemptCount = 0;
  
  const unreliableOperation = async () => {
    attemptCount++;
    logger.debug(`Attempt ${attemptCount}`);
    
    if (attemptCount < 3) {
      // Simulate network error
      const error = new Error('Network timeout');
      error.code = 'ETIMEDOUT';
      throw error;
    }
    
    return { success: true, data: 'Operation completed' };
  };
  
  try {
    const result = await retryHandler.executeWithRetry(
      unreliableOperation,
      { maxRetries: 3 },
      'unreliable_operation'
    );
    
    logger.info('Operation succeeded after retries', result);
  } catch (error) {
    logger.error('Operation failed after all retries', { error: error.message });
  }
}

/**
 * Example 3: Circuit breaker pattern
 */
async function exampleCircuitBreaker() {
  logger.info('=== Circuit Breaker Example ===');
  
  // Create retry handler with low threshold for demo
  const cbRetryHandler = new RetryHandler(logger, {
    maxRetries: 0, // No retries for faster demo
    circuitBreakerThreshold: 2,
    circuitBreakerTimeout: 5000
  });
  
  const failingOperation = async () => {
    const error = new Error('Service unavailable');
    error.response = { status: 503 };
    throw error;
  };
  
  try {
    // First failure
    await cbRetryHandler.executeWithRetry(failingOperation, {}, 'failing_op');
  } catch (error) {
    logger.info('First failure recorded');
  }
  
  try {
    // Second failure - should open circuit
    await cbRetryHandler.executeWithRetry(failingOperation, {}, 'failing_op');
  } catch (error) {
    logger.info('Second failure - circuit should be open');
  }
  
  try {
    // Third attempt - should be blocked by circuit breaker
    await cbRetryHandler.executeWithRetry(failingOperation, {}, 'failing_op');
  } catch (error) {
    logger.info('Circuit breaker blocked request', { 
      message: error.message,
      circuitOpen: error.circuitBreakerOpen 
    });
  }
  
  // Check circuit breaker status
  const status = cbRetryHandler.getCircuitBreakerStatus();
  logger.info('Circuit breaker status', status);
}

/**
 * Example 4: Discord rate limiting
 */
async function exampleDiscordRateLimit() {
  logger.info('=== Discord Rate Limiting Example ===');
  
  // Simulate Discord API calls
  const mockDiscordApiCall = async (callId) => {
    logger.debug(`Making Discord API call ${callId}`);
    
    // Simulate some processing time
    await new Promise(resolve => setTimeout(resolve, 100));
    
    return { success: true, callId };
  };
  
  // Queue multiple requests
  const promises = [];
  for (let i = 1; i <= 5; i++) {
    promises.push(
      discordRateLimit.executeRequest(
        () => mockDiscordApiCall(i),
        'test_bucket',
        { requestId: i }
      )
    );
  }
  
  try {
    const results = await Promise.all(promises);
    logger.info('All Discord API calls completed', { 
      count: results.length,
      results: results.map(r => r.callId)
    });
  } catch (error) {
    logger.error('Discord API calls failed', { error: error.message });
  }
  
  // Check rate limit status
  const rateLimitStatus = discordRateLimit.getStatus();
  logger.info('Rate limit status', rateLimitStatus);
}

/**
 * Example 5: Interaction error handling
 */
async function exampleInteractionErrorHandling() {
  logger.info('=== Interaction Error Handling Example ===');
  
  // Mock Discord interaction
  const mockInteraction = {
    user: { id: '123456789' },
    commandName: 'register',
    guildId: '987654321',
    replied: false,
    deferred: false,
    reply: async (options) => {
      logger.info('Mock interaction reply', {
        embeds: options.embeds?.length || 0,
        ephemeral: options.ephemeral
      });
      return Promise.resolve();
    }
  };
  
  // Simulate command error
  const commandError = new Error('Tournament service unavailable');
  commandError.response = { status: 503 };
  
  // Handle the interaction error
  await errorHandler.handleInteractionError(
    commandError,
    mockInteraction,
    'register_command'
  );
  
  logger.info('Interaction error handled successfully');
}

/**
 * Example 6: Performance monitoring
 */
async function examplePerformanceMonitoring() {
  logger.info('=== Performance Monitoring Example ===');
  
  const slowOperation = async () => {
    // Simulate slow operation
    await new Promise(resolve => setTimeout(resolve, 1500));
    return { data: 'Slow operation completed' };
  };
  
  const startTime = Date.now();
  const result = await slowOperation();
  const duration = Date.now() - startTime;
  
  // Log performance metrics
  logger.performance('slow_operation', duration, {
    resultSize: JSON.stringify(result).length,
    threshold: 1000
  });
}

/**
 * Example 7: Structured logging
 */
async function exampleStructuredLogging() {
  logger.info('=== Structured Logging Example ===');
  
  // Command execution logging
  logger.commandExecution('register', '123456', '789012', {
    options: { timezone: 'America/New_York' },
    sessionId: 'abc123'
  });
  
  // API request logging
  logger.apiRequest('POST', '/api/tournaments/register', {
    userId: '123456',
    sessionId: 'abc123'
  });
  
  // API response logging
  logger.apiResponse('POST', '/api/tournaments/register', 200, 250, {
    success: true,
    roomAssigned: 5
  });
  
  // Retry attempt logging
  logger.retryAttempt('register_player', 2, 3, 2000, {
    userId: '123456',
    errorType: 'NetworkError'
  });
  
  // Interaction timeout logging
  logger.interactionTimeout('register', '123456', {
    duration: 15000,
    reason: 'user_inactive'
  });
}

/**
 * Run all examples
 */
async function runAllExamples() {
  try {
    await exampleBasicErrorHandling();
    await exampleRetryLogic();
    await exampleCircuitBreaker();
    await exampleDiscordRateLimit();
    await exampleInteractionErrorHandling();
    await examplePerformanceMonitoring();
    await exampleStructuredLogging();
    
    logger.info('All examples completed successfully');
  } catch (error) {
    logger.error('Example execution failed', {
      error: error.message,
      stack: error.stack
    });
  }
}

// Run examples if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllExamples();
}