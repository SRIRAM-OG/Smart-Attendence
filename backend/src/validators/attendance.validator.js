const Joi = require('joi');

const createSessionSchema = Joi.object({
  courseId: Joi.string().uuid().required(),
  sessionDate: Joi.date().iso().default(() => new Date()),
  startTime: Joi.date().iso().default(() => new Date()),
  expiryMinutes: Joi.number().integer().min(1).max(60).default(5),
});

const generateQrSchema = Joi.object({
  expiryMinutes: Joi.number().integer().min(1).max(60).default(5),
});

const scanAttendanceSchema = Joi.object({
  sessionId: Joi.string().uuid().required(),
  token: Joi.string().required(),
  authMethod: Joi.string().valid('QR_SCAN', 'MANUAL_ENTRY', 'BIOMETRIC').default('QR_SCAN'),
});

const updateRecordSchema = Joi.object({
  status: Joi.string().valid('PRESENT', 'ABSENT', 'LATE').required(),
});

module.exports = {
  createSessionSchema,
  generateQrSchema,
  scanAttendanceSchema,
  updateRecordSchema,
};
