/**
 * Unit & API Integration Tests for PulseCare Healthcare System
 * Uses Node.js native test runner (compatible with Node 18+ and Alpine)
 */

const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const app = require('../src/server');

let server;
let baseUrl;

test.before(async () => {
  return new Promise((resolve) => {
    // Start test server on random free port
    server = app.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

test.after(async () => {
  return new Promise((resolve) => {
    server.close(resolve);
  });
});

// Helper for making HTTP requests
function request(path, options = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const reqOptions = {
      method: options.method || 'GET',
      headers: options.headers || {},
    };

    const req = http.request(url, reqOptions, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        let json;
        try {
          json = JSON.parse(body);
        } catch (e) {
          json = body;
        }
        resolve({ status: res.statusCode, headers: res.headers, body: json });
      });
    });

    req.on('error', reject);

    if (options.body) {
      req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
    }
    req.end();
  });
}

test('Kubernetes Liveness Probe (/healthz) returns 200 and UP', async () => {
  const res = await request('/healthz');
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.status, 'UP');
  assert.strictEqual(res.body.check, 'liveness');
  assert.ok(res.body.version);
});

test('Kubernetes Readiness Probe (/readyz) returns 200 and READY', async () => {
  const res = await request('/readyz');
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.status, 'READY');
});

test('DevOps /api/info exposes Blue-Green deployment metadata & HIPAA status', async () => {
  const res = await request('/api/info');
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.hipaaCompliant, true);
  assert.strictEqual(res.body.securityScanStatus, 'PASSED');
  assert.ok(['blue', 'green'].includes(res.body.deploymentColor));
});

test('Hospital Statistics API (/api/stats) returns valid medical metrics', async () => {
  const res = await request('/api/stats');
  assert.strictEqual(res.status, 200);
  assert.ok(res.body.totalBeds > 0);
  assert.ok(res.body.availableBeds > 0);
  assert.ok(res.body.emergencyResponseAvgMins < 10);
});

test('Doctors Catalog API (/api/doctors) returns specialist directory', async () => {
  const res = await request('/api/doctors');
  assert.strictEqual(res.status, 200);
  assert.ok(Array.isArray(res.body));
  assert.ok(res.body.length >= 3);
  assert.strictEqual(res.body[0].department, 'Cardiology');
});

test('Appointments API creates and lists patient appointments', async () => {
  const newAppointment = {
    patientName: 'John Doe',
    patientEmail: 'johndoe@test.org',
    patientPhone: '+1-555-0199',
    doctor: 'Dr. Emily Vance (Cardiology)',
    date: '2026-11-01',
    time: '11:00 AM',
    reason: 'Follow-up ECG check'
  };

  const postRes = await request('/api/appointments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: newAppointment
  });

  assert.strictEqual(postRes.status, 201);
  assert.strictEqual(postRes.body.success, true);
  assert.ok(postRes.body.appointment.id.startsWith('APT-'));

  const listRes = await request('/api/appointments');
  assert.strictEqual(listRes.status, 200);
  const found = listRes.body.some(a => a.patientName === 'John Doe');
  assert.strictEqual(found, true);
});

test('Appointments API rejects invalid request payload', async () => {
  const res = await request('/api/appointments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: { patientName: 'Only Name' } // missing required fields
  });

  assert.strictEqual(res.status, 400);
  assert.ok(res.body.error);
});

test('Patient EHR Records API (/api/records) returns encrypted record simulation', async () => {
  const res = await request('/api/records');
  assert.strictEqual(res.status, 200);
  assert.strictEqual(res.body.patientId, 'HP-89421');
  assert.ok(res.body.recentVitals.bloodPressure);
  assert.ok(Array.isArray(res.body.recentPrescriptions));
});
