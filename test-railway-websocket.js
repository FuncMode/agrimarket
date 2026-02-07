// test-railway-websocket.js (Node.js test)
const io = require('socket.io-client');

console.log('🧪 Testing Railway WebSocket Connection...\n');

const socket = io('https://agrimarket-production-04b3.up.railway.app', {
  timeout: 10000,
  transports: ['websocket', 'polling'],
  forceNew: true
});

socket.on('connect', () => {
  console.log('✅ WebSocket connected successfully!');
  console.log('   Socket ID:', socket.id);
  socket.disconnect();
});

socket.on('connect_error', (error) => {
  console.log('❌ WebSocket connection failed:');
  console.log('   Error:', error.message);
  console.log('   Type:', error.type);
  
  if (error.message.includes('CORS')) {
    console.log('\n💡 CORS Issue Detected!');
    console.log('   Fix: Go to Railway dashboard → Variables');
    console.log('   Add: CORS_ORIGIN=https://agri-market-delta.vercel.app');
  }
});

socket.on('disconnect', (reason) => {
  console.log('🔌 WebSocket disconnected:', reason);
  process.exit(0);
});

setTimeout(() => {
  console.log('⏰ Connection timeout - Railway WebSocket might be down');
  process.exit(1);
}, 12000);