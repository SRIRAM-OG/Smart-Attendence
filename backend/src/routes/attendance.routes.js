const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendance.controller');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/role');
const validate = require('../middleware/validate');
const {
  createSessionSchema,
  generateQrSchema,
  scanAttendanceSchema,
  updateRecordSchema,
} = require('../validators/attendance.validator');

// All attendance routes require authentication
router.use(authenticate);

// Student endpoints
router.post(
  '/scan',
  authorize('STUDENT'),
  validate(scanAttendanceSchema),
  attendanceController.scanAttendance
);
router.get('/my-history', authorize('STUDENT'), attendanceController.getMyHistory);
router.get('/my-percentage', authorize('STUDENT'), attendanceController.getMyPercentage);

// Teacher endpoints
router.post(
  '/sessions',
  authorize('TEACHER'),
  validate(createSessionSchema),
  attendanceController.createSession
);
router.post(
  '/sessions/:id/generate-qr',
  authorize('TEACHER'),
  validate(generateQrSchema),
  attendanceController.generateQr
);
router.get(
  '/sessions/:id/records',
  authorize('TEACHER', 'ADMIN'),
  attendanceController.getSessionRecords
);
router.patch(
  '/sessions/:id/close',
  authorize('TEACHER'),
  attendanceController.closeSession
);

// Attendance Correction (Teacher & Admin)
router.patch(
  '/records/:id',
  authorize('TEACHER', 'ADMIN'),
  validate(updateRecordSchema),
  attendanceController.updateRecord
);

module.exports = router;
