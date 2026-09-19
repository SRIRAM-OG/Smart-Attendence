const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/role');
const validate = require('../middleware/validate');
const {
  createDepartmentSchema,
  createStudentSchema,
  updateStudentSchema,
  createTeacherSchema,
  updateTeacherSchema,
  createCourseSchema,
  enrollStudentSchema,
  assignTeacherSchema,
} = require('../validators/admin.validator');

// All admin routes require authentication and ADMIN role
router.use(authenticate, authorize('ADMIN'));

// Dashboard Stats
router.get('/dashboard-stats', adminController.getDashboardStats);

// Departments
router.get('/departments', adminController.getDepartments);
router.post('/departments', validate(createDepartmentSchema), adminController.createDepartment);

// Students
router.get('/students', adminController.getStudents);
router.post('/students', validate(createStudentSchema), adminController.createStudent);
router.put('/students/:id', validate(updateStudentSchema), adminController.updateStudent);
router.delete('/students/:id', adminController.deleteStudent);

// Teachers
router.get('/teachers', adminController.getTeachers);
router.post('/teachers', validate(createTeacherSchema), adminController.createTeacher);
router.put('/teachers/:id', validate(updateTeacherSchema), adminController.updateTeacher);

// Courses
router.get('/courses', adminController.getCourses);
router.post('/courses', validate(createCourseSchema), adminController.createCourse);

// Enrollments & Assignments
router.post('/enrollments', validate(enrollStudentSchema), adminController.enrollStudent);
router.delete('/enrollments/:id', adminController.removeEnrollment);
router.post('/assign-teacher', validate(assignTeacherSchema), adminController.assignTeacher);
router.delete('/assign-teacher/:teacherId/:courseId', adminController.removeTeacherAssignment);

// Audit Logs
router.get('/audit-logs', adminController.getAuditLogs);

module.exports = router;
