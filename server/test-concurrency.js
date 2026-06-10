const http = require('http');

const PORT = process.env.PORT || 3000;
const HOST = 'localhost';

const bookingData = JSON.stringify({
    venue_id: 'ENTER_A_VALID_VENUE_UUID_HERE',
    date: '2026-06-11',
    start_time: '10:00'
});

function makeRequest(userId) {
    return new Promise((resolve, reject) => {
        const req = http.request({
            hostname: HOST,
            port: PORT,
            path: '/bookings',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(bookingData),
                'X-User-Id': userId
            }
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    body: JSON.parse(data)
                });
            });
        });

        req.on('error', reject);
        req.write(bookingData);
        req.end();
    });
}

async function testConcurrency() {
    console.log('--- Simulating Concurrent Bookings ---');
    console.log('Make sure the server is running on port 3000');
    console.log('Make sure to replace VENUE_UUID in this script with a valid ID from GET /venues');
    console.log('Sending requests simultaneously for Alice and Bob...\n');

    try {
        const results = await Promise.all([
            makeRequest('user_alice'),
            makeRequest('user_bob')
        ]);

        results.forEach((res, idx) => {
            const user = idx === 0 ? 'Alice' : 'Bob';
            console.log(`User ${user} response:`);
            console.log(`Status Code: ${res.statusCode}`);
            console.log(`Body:`, res.body);
            console.log('------------------------------------');
        });
    } catch (err) {
        console.error('Request failed:', err.message);
    }
}

testConcurrency();
