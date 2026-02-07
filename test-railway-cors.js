// test-railway-cors.js - Test Railway CORS configuration
console.log('🧪 Testing Railway CORS Configuration...\n');

const API_BASE = 'https://agrimarket-production-04b3.up.railway.app';

async function testCorsWithOrigin() {
  try {
    const response = await fetch(`${API_BASE}/api/health`, {
      method: 'GET',
      headers: {
        'Origin': 'https://agri-market-delta.vercel.app',
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Status:', response.status);
    console.log('✅ CORS Headers:');
    response.headers.forEach((value, key) => {
      if (key.toLowerCase().includes('access-control')) {
        console.log(`   ${key}: ${value}`);
      }
    });

    if (response.ok) {
      const data = await response.json();
      console.log('✅ Response data:', data);
      console.log('\n🎉 CORS is working correctly!');
    }
    
  } catch (error) {
    console.log('❌ CORS Test Failed:', error.message);
    console.log('\n💡 This means Railway CORS_ORIGIN is NOT set to:');
    console.log('   https://agri-market-delta.vercel.app');
    console.log('\n🔧 Fix: Go to Railway dashboard → Variables tab');
    console.log('   Set: CORS_ORIGIN=https://agri-market-delta.vercel.app');
  }
}

testCorsWithOrigin();