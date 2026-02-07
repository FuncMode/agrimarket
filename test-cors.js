// test-cors.js - Quick CORS test script
const API_BASE = 'https://agrimarket-production-9247.up.railway.app';

async function testCORS() {
    console.log('🧪 Testing CORS Configuration...\n');
    
    try {
        // Test basic endpoint
        const response = await fetch(`${API_BASE}/api/health`, {
            method: 'GET',
            headers: {
                'Origin': 'https://agri-market-delta.vercel.app',
                'Content-Type': 'application/json'
            }
        });
        
        console.log('✅ Status:', response.status);
        console.log('✅ CORS Headers:');
        console.log('   Access-Control-Allow-Origin:', response.headers.get('Access-Control-Allow-Origin'));
        console.log('   Access-Control-Allow-Credentials:', response.headers.get('Access-Control-Allow-Credentials'));
        
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Response:', JSON.stringify(data, null, 2));
            console.log('\n🎉 CORS is working!');
        } else {
            console.log('❌ API returned error status');
        }
        
    } catch (error) {
        console.log('❌ CORS Test Failed:');
        console.log('   Error:', error.message);
        console.log('\n💡 Possible issues:');
        console.log('   1. Railway environment variables not updated');
        console.log('   2. Railway not redeployed yet');
        console.log('   3. CORS_ORIGIN still pointing to wrong URL');
    }
}

testCORS();