const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/role');

// All report routes require authentication
router.use(authenticate);

// Student report (Accessible by Admin, Teacher, or the Student themselves)
router.get('/student/:id', authorize('ADMIN', 'TEACHER', 'STUDENT'), reportController.getStudentReport);

// Course report (Accessible by Admin, Teacher)
router.get('/course/:id', authorize('ADMIN', 'TEACHER'), reportController.getCourseReport);

// Low attendance report (Accessible by Admin, Teacher)
router.get('/low-attendance', authorize('ADMIN', 'TEACHER'), reportController.getLowAttendance);

// Daily report (Accessible by Admin, Teacher)
router.get('/daily', authorize('ADMIN', 'TEACHER'), reportController.getDailyReport);

module.exports = router;
