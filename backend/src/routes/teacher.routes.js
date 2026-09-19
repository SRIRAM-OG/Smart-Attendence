const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacher.controller');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/role');

// All teacher routes require authentication and TEACHER role
router.use(authenticate, authorize('TEACHER'));

router.get('/profile', teacherController.getProfile);
router.get('/courses', teacherController.getCourses);
router.get('/sessions', teacherController.getSessions);

module.exports = router;
