const qrService = require('../src/services/qr.service');

describe('QR Service Tests', () => {
  const sessionId = 'test-session-uuid-1234';

  test('should generate a valid signed QR token with payload', () => {
    const { token, expiresAt, payload } = qrService.generateQrToken(sessionId, 5);

    expect(token).toBeDefined();
    expect(typeof token).toBe('string');
    expect(token.split('.')).toHaveLength(2);

    expect(expiresAt).toBeInstanceOf(Date);
    expect(expiresAt.getTime()).toBeGreaterThan(Date.now());

    expect(payload).toBeDefined();
    const parsed = JSON.parse(payload);
    expect(parsed.sessionId).toBe(sessionId);
    expect(parsed.token).toBe(token);
    expect(parsed.expiresAt).toBe(expiresAt.toISOString());
  });

  test('should validate a freshly generated token as TRUE', () => {
    const { token, expiresAt } = qrService.generateQrToken(sessionId, 10);
    const isValid = qrService.validateQrToken(sessionId, token, expiresAt);
    expect(isValid).toBe(true);
  });

  test('should reject a token with incorrect sessionId', () => {
    const { token, expiresAt } = qrService.generateQrToken(sessionId, 10);
    const isValid = qrService.validateQrToken('wrong-session-id', token, expiresAt);
    expect(isValid).toBe(false);
  });

  test('should reject a tampered token signature', () => {
    const { token, expiresAt } = qrService.generateQrToken(sessionId, 10);
    const tamperedToken = token.slice(0, -4) + 'abcd';
    const isValid = qrService.validateQrToken(sessionId, tamperedToken, expiresAt);
    expect(isValid).toBe(false);
  });

  test('should reject an expired token', () => {
    const pastExpiresAt = new Date(Date.now() - 5000); // 5 seconds in past
    const { token } = qrService.generateQrToken(sessionId, -1);
    const isValid = qrService.validateQrToken(sessionId, token, pastExpiresAt);
    expect(isValid).toBe(false);
  });
});
