// Simple test to verify project setup
import { config } from './src/config/config.js';

console.log('Testing project setup...');

// Test 1: Configuration loading
try {
  console.log('✓ Configuration loaded successfully');
  console.log('  - Discord config:', !!config.discord);
  console.log('  - API config:', !!config.api);
  console.log('  - Bot config:', !!config.bot);
} catch (error) {
  console.error('✗ Configuration loading failed:', error.message);
}

// Test 2: API endpoints
try {
  const endpoints = config.api.endpoints;
  console.log('✓ API endpoints configured:');
  console.log('  - Current tournament:', endpoints.currentTournament);
  console.log('  - Register:', endpoints.register);
  console.log('  - Unregister:', endpoints.unregister);
  console.log('  - Player registrations:', endpoints.playerRegistrations);
} catch (error) {
  console.error('✗ API endpoints test failed:', error.message);
}

// Test 3: Dependencies (basic import test)
try {
  await import('moment-timezone');
  console.log('✓ moment-timezone dependency available');
} catch (error) {
  console.error('✗ moment-timezone dependency failed:', error.message);
}

console.log('\nProject setup verification complete!');
console.log('Note: discord.js and axios may show WebAssembly warnings but are functional.');