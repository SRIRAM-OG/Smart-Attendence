const request = require('supertest');
const app = require('../src/index');

describe('Auth & Health API Tests', () => {
  test('GET /api/health should return status healthy', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
  });

  test('POST /api/auth/login with missing body should return 400 Bad Request', async () => {
    const res = await request(app).post('/api/auth/login').send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('POST /api/auth/login with invalid email format should return 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: 'password123' });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('POST /api/auth/register with missing fields should return 400', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Test Student',
      email: 'test@student.com',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('Protected route /api/students/profile without token should return 401 Unauthorized', async () => {
    const res = await request(app).get('/api/students/profile');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
