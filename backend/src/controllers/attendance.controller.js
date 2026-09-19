const attendanceService = require('../services/attendance.service');
const ApiError = require('../utils/apiError');

class AttendanceController {
  /**
   * Teacher creates attendance session
   */
  async createSession(req, res, next) {
    try {
      const teacherId = req.user.teacherId;
      if (!teacherId) {
        throw ApiError.forbidden('Only teachers can create attendance sessions');
      }

      const result = await attendanceService.createSession(teacherId, req.body);
      res.status(201).json({
        success: true,
        message: 'Attendance session created and QR code generated',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Teacher regenerates QR code for an active session
   */
  async generateQr(req, res, next) {
    try {
      const teacherId = req.user.teacherId;
      if (!teacherId) {
        throw ApiError.forbidden('Only teachers can regenerate QR codes');
      }

      const { id } = req.params;
      const { expiryMinutes } = req.body;
      const result = await attendanceService.generateSessionQr(teacherId, id, expiryMinutes);

      res.status(200).json({
        success: true,
        message: 'QR code regenerated successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Student scans QR and marks attendance
   */
  async scanAttendance(req, res, next) {
    try {
      const studentId = req.user.studentId;
      if (!studentId) {
        throw ApiError.forbidden('Only students can mark attendance via QR scan');
      }

      const result = await attendanceService.scanAttendance(studentId, req.user.id, req.body);
      res.status(200).json({
        success: true,
        message: result.message,
        data: result.record,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get all attendance records for a session (Teacher monitor)
   */
  async getSessionRecords(req, res, next) {
    try {
      const { id } = req.params;
      const result = await attendanceService.getSessionRecords(id, req.user.teacherId);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Teacher closes attendance session
   */
  async closeSession(req, res, next) {
    try {
      const teacherId = req.user.teacherId;
      if (!teacherId) {
        throw ApiError.forbidden('Only teachers can close sessions');
      }

      const { id } = req.params;
      const result = await attendanceService.closeSession(id, teacherId);

      res.status(200).json({
        success: true,
        message: 'Attendance session closed successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Student views their personal attendance history
   */
  async getMyHistory(req, res, next) {
    try {
      const studentId = req.user.studentId;
      if (!studentId) {
        throw ApiError.forbidden('Only students can view their attendance history');
      }

      const { courseId } = req.query;
      const records = await attendanceService.getStudentHistory(studentId, courseId);

      res.status(200).json({
        success: true,
        data: records,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Student views calculated attendance percentage
   */
  async getMyPercentage(req, res, next) {
    try {
      const studentId = req.user.studentId;
      if (!studentId) {
        throw ApiError.forbidden('Only students can view their attendance percentage');
      }

      const summary = await attendanceService.getStudentPercentage(studentId);

      res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Teacher / Admin updates an attendance record (Attendance correction)
   */
  async updateRecord(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const updated = await attendanceService.updateRecord(id, status, req.user.id);

      res.status(200).json({
        success: true,
        message: 'Attendance record updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AttendanceController();
