const reportService = require('../services/report.service');

class ReportController {
  /**
   * Student attendance report
   */
  async getStudentReport(req, res, next) {
    try {
      const { id } = req.params;
      const report = await reportService.getStudentReport(id);
      res.status(200).json({
        success: true,
        data: report,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Course attendance report
   */
  async getCourseReport(req, res, next) {
    try {
      const { id } = req.params;
      const report = await reportService.getCourseReport(id);
      res.status(200).json({
        success: true,
        data: report,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Low attendance students list (<75%)
   */
  async getLowAttendance(req, res, next) {
    try {
      const { threshold = 75 } = req.query;
      const list = await reportService.getLowAttendance(Number(threshold));
      res.status(200).json({
        success: true,
        data: list,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Daily attendance summary
   */
  async getDailyReport(req, res, next) {
    try {
      const { date } = req.query;
      const report = await reportService.getDailyReport(date);
      res.status(200).json({
        success: true,
        data: report,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportController();
