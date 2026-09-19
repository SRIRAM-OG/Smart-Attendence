const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const QR_SECRET = process.env.JWT_SECRET || 'qr_session_signing_secret_2026';

class QrService {
  /**
   * Generates a signed QR token with expiry metadata
   * @param {string} sessionId
   * @param {number} expiryMinutes
   * @returns {{ token: string, expiresAt: Date, payload: string }}
   */
  generateQrToken(sessionId, expiryMinutes = 5) {
    const rawUuid = uuidv4();
    const timestamp = Date.now();
    const expiresAt = new Date(timestamp + expiryMinutes * 60 * 1000);

    // Create HMAC signature for tamper-proof verification
    const dataToSign = `${sessionId}:${rawUuid}:${expiresAt.toISOString()}`;
    const signature = crypto
      .createHmac('sha256', QR_SECRET)
      .update(dataToSign)
      .digest('hex');

    const token = `${rawUuid}.${signature}`;

    // Payload embedded into QR code (JSON string)
    const payload = JSON.stringify({
      sessionId,
      token,
      expiresAt: expiresAt.toISOString(),
      generatedAt: new Date(timestamp).toISOString(),
    });

    return {
      token,
      expiresAt,
      payload,
    };
  }

  /**
   * Validates if a token matches the expected signature and expiry
   * @param {string} sessionId
   * @param {string} token
   * @param {Date} expiresAt
   * @returns {boolean}
   */
  validateQrToken(sessionId, token, expiresAt) {
    if (!token || !sessionId || !expiresAt) return false;

    const parts = token.split('.');
    if (parts.length !== 2) return false;

    const [rawUuid, signature] = parts;
    const expiryIso = typeof expiresAt === 'string' ? expiresAt : expiresAt.toISOString();

    const expectedData = `${sessionId}:${rawUuid}:${expiryIso}`;
    const expectedSignature = crypto
      .createHmac('sha256', QR_SECRET)
      .update(expectedData)
      .digest('hex');

    if (signature !== expectedSignature) {
      return false;
    }

    const now = new Date();
    const exp = new Date(expiresAt);
    return now <= exp;
  }
}

module.exports = new QrService();
