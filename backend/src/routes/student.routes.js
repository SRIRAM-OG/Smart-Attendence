const express = require('express');
const router = express.Router();
const studentController = require('../controllers/student.controller');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/role');

// All student routes require authentication and STUDENT role
router.use(authenticate, authorize('STUDENT'));

router.get('/profile', studentController.getProfile);
router.get('/courses', studentController.getCourses);
router.get('/attendance', studentController.getAttendanceHistory);
router.get('/percentage', studentController.getAttendancePercentage);

module.exports = router;
