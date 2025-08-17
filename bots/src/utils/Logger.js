import fs from 'fs';
import path from 'path';

/**
 * Comprehensive logging system for the Discord Tournament Bot
 * Provides structured logging with different levels and output formats
 */
export class Logger {
  constructor(options = {}) {
    this.options = {
      level: options.level || 'info',
      console: options.console !== false, // Default to true
      file: options.file || null,
      maxFileSize: options.maxFileSize || 10 * 1024 * 1024, // 10MB
      maxFiles: options.maxFiles || 5,
      format: options.format || 'json', // 'json' or 'text'
      ...options
    };

    // Log levels (lower number = higher priority)
    this.levels = {
      error: 0,
      warn: 1,
      info: 2,
      debug: 3,
      trace: 4
    };

    // Colors for console output
    this.colors = {
      error: '\x1b[31m', // Red
      warn: '\x1b[33m',  // Yellow
      info: '\x1b[36m',  // Cyan
      debug: '\x1b[35m', // Magenta
      trace: '\x1b[37m', // White
      reset: '\x1b[0m'
    };

    // Ensure log directory exists if file logging is enabled
    if (this.options.file) {
      this.ensureLogDirectory();
    }
  }

  /**
   * Ensure log directory exists
   */
  ensureLogDirectory() {
    const logDir = path.dirname(this.options.file);
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
  }

  /**
   * Check if a log level should be output
   * @param {string} level - Log level to check
   * @returns {boolean} Whether to output this level
   */
  shouldLog(level) {
    const currentLevelValue = this.levels[this.options.level] || 2;
    const messageLevelValue = this.levels[level] || 2;
    return messageLevelValue <= currentLevelValue;
  }

  /**
   * Format log message
   * @param {string} level - Log level
   * @param {string} message - Log message
   * @param {Object} metadata - Additional metadata
   * @returns {Object} Formatted log entry
   */
  formatMessage(level, message, metadata = {}) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level: level.toUpperCase(),
      message,
      ...metadata
    };

    // Add process information
    logEntry.pid = process.pid;
    logEntry.hostname = process.env.HOSTNAME || 'unknown';

    return logEntry;
  }

  /**
   * Format log entry for console output
   * @param {Object} logEntry - Log entry object
   * @returns {string} Formatted string for console
   */
  formatForConsole(logEntry) {
    const color = this.colors[logEntry.level.toLowerCase()] || this.colors.info;
    const reset = this.colors.reset;
    
    let output = `${color}[${logEntry.timestamp}] ${logEntry.level}: ${logEntry.message}${reset}`;
    
    // Add metadata if present
    const metadata = { ...logEntry };
    delete metadata.timestamp;
    delete metadata.level;
    delete metadata.message;
    delete metadata.pid;
    delete metadata.hostname;
    
    if (Object.keys(metadata).length > 0) {
      output += `\n${color}  Metadata: ${JSON.stringify(metadata, null, 2)}${reset}`;
    }
    
    return output;
  }

  /**
   * Write log entry to file
   * @param {Object} logEntry - Log entry to write
   */
  writeToFile(logEntry) {
    if (!this.options.file) return;

    try {
      // Check file size and rotate if necessary
      this.rotateLogIfNeeded();

      const logLine = this.options.format === 'json' 
        ? JSON.stringify(logEntry) + '\n'
        : this.formatForConsole(logEntry) + '\n';

      fs.appendFileSync(this.options.file, logLine);
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  /**
   * Rotate log file if it exceeds maximum size
   */
  rotateLogIfNeeded() {
    if (!fs.existsSync(this.options.file)) return;

    const stats = fs.statSync(this.options.file);
    if (stats.size < this.options.maxFileSize) return;

    // Rotate existing files
    const logDir = path.dirname(this.options.file);
    const logName = path.basename(this.options.file, path.extname(this.options.file));
    const logExt = path.extname(this.options.file);

    // Move existing rotated files
    for (let i = this.options.maxFiles - 1; i > 0; i--) {
      const oldFile = path.join(logDir, `${logName}.${i}${logExt}`);
      const newFile = path.join(logDir, `${logName}.${i + 1}${logExt}`);
      
      if (fs.existsSync(oldFile)) {
        if (i === this.options.maxFiles - 1) {
          fs.unlinkSync(oldFile); // Delete oldest file
        } else {
          fs.renameSync(oldFile, newFile);
        }
      }
    }

    // Move current file to .1
    const rotatedFile = path.join(logDir, `${logName}.1${logExt}`);
    fs.renameSync(this.options.file, rotatedFile);
  }

  /**
   * Core logging method
   * @param {string} level - Log level
   * @param {string} message - Log message
   * @param {Object} metadata - Additional metadata
   */
  log(level, message, metadata = {}) {
    if (!this.shouldLog(level)) return;

    const logEntry = this.formatMessage(level, message, metadata);

    // Output to console
    if (this.options.console) {
      console.log(this.formatForConsole(logEntry));
    }

    // Write to file
    if (this.options.file) {
      this.writeToFile(logEntry);
    }
  }

  /**
   * Log error message
   * @param {string} message - Error message
   * @param {Object} metadata - Additional metadata
   */
  error(message, metadata = {}) {
    this.log('error', message, metadata);
  }

  /**
   * Log warning message
   * @param {string} message - Warning message
   * @param {Object} metadata - Additional metadata
   */
  warn(message, metadata = {}) {
    this.log('warn', message, metadata);
  }

  /**
   * Log info message
   * @param {string} message - Info message
   * @param {Object} metadata - Additional metadata
   */
  info(message, metadata = {}) {
    this.log('info', message, metadata);
  }

  /**
   * Log debug message
   * @param {string} message - Debug message
   * @param {Object} metadata - Additional metadata
   */
  debug(message, metadata = {}) {
    this.log('debug', message, metadata);
  }

  /**
   * Log trace message
   * @param {string} message - Trace message
   * @param {Object} metadata - Additional metadata
   */
  trace(message, metadata = {}) {
    this.log('trace', message, metadata);
  }

  /**
   * Log API request
   * @param {string} method - HTTP method
   * @param {string} url - Request URL
   * @param {Object} metadata - Additional request metadata
   */
  apiRequest(method, url, metadata = {}) {
    this.info(`API Request: ${method.toUpperCase()} ${url}`, {
      type: 'api_request',
      method: method.toUpperCase(),
      url,
      ...metadata
    });
  }

  /**
   * Log API response
   * @param {string} method - HTTP method
   * @param {string} url - Request URL
   * @param {number} status - Response status code
   * @param {number} duration - Request duration in ms
   * @param {Object} metadata - Additional response metadata
   */
  apiResponse(method, url, status, duration, metadata = {}) {
    const level = status >= 400 ? 'error' : status >= 300 ? 'warn' : 'info';
    this.log(level, `API Response: ${method.toUpperCase()} ${url} - ${status} (${duration}ms)`, {
      type: 'api_response',
      method: method.toUpperCase(),
      url,
      status,
      duration,
      ...metadata
    });
  }

  /**
   * Log Discord command execution
   * @param {string} commandName - Command name
   * @param {string} userId - User ID
   * @param {string} guildId - Guild ID
   * @param {Object} metadata - Additional command metadata
   */
  commandExecution(commandName, userId, guildId, metadata = {}) {
    this.info(`Command executed: /${commandName}`, {
      type: 'command_execution',
      command: commandName,
      userId,
      guildId,
      ...metadata
    });
  }

  /**
   * Log Discord interaction timeout
   * @param {string} interactionType - Type of interaction
   * @param {string} userId - User ID
   * @param {Object} metadata - Additional metadata
   */
  interactionTimeout(interactionType, userId, metadata = {}) {
    this.warn(`Interaction timeout: ${interactionType}`, {
      type: 'interaction_timeout',
      interactionType,
      userId,
      ...metadata
    });
  }

  /**
   * Log retry attempt
   * @param {string} operation - Operation being retried
   * @param {number} attempt - Attempt number
   * @param {number} maxAttempts - Maximum attempts
   * @param {number} delay - Delay before retry in ms
   * @param {Object} metadata - Additional metadata
   */
  retryAttempt(operation, attempt, maxAttempts, delay, metadata = {}) {
    this.warn(`Retry attempt ${attempt}/${maxAttempts} for ${operation} (delay: ${delay}ms)`, {
      type: 'retry_attempt',
      operation,
      attempt,
      maxAttempts,
      delay,
      ...metadata
    });
  }

  /**
   * Log performance metrics
   * @param {string} operation - Operation name
   * @param {number} duration - Duration in milliseconds
   * @param {Object} metadata - Additional metrics
   */
  performance(operation, duration, metadata = {}) {
    const level = duration > 5000 ? 'warn' : duration > 1000 ? 'info' : 'debug';
    this.log(level, `Performance: ${operation} completed in ${duration}ms`, {
      type: 'performance',
      operation,
      duration,
      ...metadata
    });
  }

  /**
   * Create a child logger with additional context
   * @param {Object} context - Additional context to include in all logs
   * @returns {Logger} Child logger instance
   */
  child(context = {}) {
    const childLogger = new Logger(this.options);
    
    // Override log method to include context
    const originalLog = childLogger.log.bind(childLogger);
    childLogger.log = (level, message, metadata = {}) => {
      return originalLog(level, message, { ...context, ...metadata });
    };
    
    return childLogger;
  }
}

// Create default logger instance
export const logger = new Logger({
  level: process.env.LOG_LEVEL || 'info',
  file: process.env.LOG_FILE || './logs/bot.log',
  console: process.env.LOG_CONSOLE !== 'false',
  maxFileSize: parseInt(process.env.LOG_MAX_FILE_SIZE) || 10 * 1024 * 1024,
  maxFiles: parseInt(process.env.LOG_MAX_FILES) || 5
});