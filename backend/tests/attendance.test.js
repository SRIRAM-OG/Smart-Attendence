const request = require('supertest');
const app = require('../src/index');

describe('Attendance Route Protection Tests', () => {
  test('POST /api/attendance/sessions without auth should return 401', async () => {
    const res = await request(app).post('/api/attendance/sessions').send({
      courseId: '123e4567-e89b-12d3-a456-426614174000',
    });
    expect(res.statusCode).toBe(401);
  });

  test('POST /api/attendance/scan without auth should return 401', async () => {
    const res = await request(app).post('/api/attendance/scan').send({
      sessionId: '123e4567-e89b-12d3-a456-426614174000',
      token: 'dummy-token',
    });
    expect(res.statusCode).toBe(401);
  });

  test('GET /api/attendance/my-percentage without auth should return 401', async () => {
    const res = await request(app).get('/api/attendance/my-percentage');
    expect(res.statusCode).toBe(401);
  });
});
