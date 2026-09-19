const Joi = require('joi');

const createDepartmentSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100).required(),
  code: Joi.string().trim().uppercase().min(2).max(10).required(),
});

const createStudentSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100).required(),
  email: Joi.string().email().trim().lowercase().required(),
  password: Joi.string().min(6).required(),
  enrollmentNumber: Joi.string().trim().required(),
  departmentId: Joi.string().uuid().required(),
  semester: Joi.number().integer().min(1).max(12).default(1),
  section: Joi.string().trim().max(10).default('A'),
});

const updateStudentSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100),
  departmentId: Joi.string().uuid(),
  semester: Joi.number().integer().min(1).max(12),
  section: Joi.string().trim().max(10),
  status: Joi.string().valid('ACTIVE', 'INACTIVE'),
});

const createTeacherSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100).required(),
  email: Joi.string().email().trim().lowercase().required(),
  password: Joi.string().min(6).required(),
  departmentId: Joi.string().uuid().required(),
});

const updateTeacherSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100),
  departmentId: Joi.string().uuid(),
  status: Joi.string().valid('ACTIVE', 'INACTIVE'),
});

const createCourseSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100).required(),
  code: Joi.string().trim().uppercase().min(2).max(20).required(),
  departmentId: Joi.string().uuid().required(),
});

const enrollStudentSchema = Joi.object({
  studentId: Joi.string().uuid().required(),
  courseId: Joi.string().uuid().required(),
  academicYear: Joi.string().trim().default('2025-2026'),
});

const assignTeacherSchema = Joi.object({
  teacherId: Joi.string().uuid().required(),
  courseId: Joi.string().uuid().required(),
});

module.exports = {
  createDepartmentSchema,
  createStudentSchema,
  updateStudentSchema,
  createTeacherSchema,
  updateTeacherSchema,
  createCourseSchema,
  enrollStudentSchema,
  assignTeacherSchema,
};
