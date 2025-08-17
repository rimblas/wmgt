// Test setup and utilities
// This will be expanded in task 12
export const mockDiscordInteraction = {
  user: {
    id: '123456789012345678',
    username: 'testuser',
    globalName: 'Test User'
  },
  reply: async (content) => {
    console.log('Mock reply:', content);
  },
  editReply: async (content) => {
    console.log('Mock edit reply:', content);
  }
};