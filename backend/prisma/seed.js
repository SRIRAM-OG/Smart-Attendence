const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Smart Attendance App database...');

  // 1. Clean existing records in reverse dependency order
  await prisma.auditLog.deleteMany();
  await prisma.attendanceRecord.deleteMany();
  await prisma.attendanceSession.deleteMany();
  await prisma.enrollment.deleteMany();
  await prisma.teacherCourse.deleteMany();
  await prisma.course.deleteMany();
  await prisma.student.deleteMany();
  await prisma.teacher.deleteMany();
  await prisma.department.deleteMany();
  await prisma.user.deleteMany();

  console.log('Cleared existing data.');

  // Password hashes
  const adminPass = await bcrypt.hash('admin123', 10);
  const teacherPass = await bcrypt.hash('teacher123', 10);
  const studentPass = await bcrypt.hash('student123', 10);

  // 2. Create Admin User
  const adminUser = await prisma.user.create({
    data: {
      name: 'System Administrator',
      email: 'admin@smart.edu',
      passwordHash: adminPass,
      role: 'ADMIN',
      status: 'ACTIVE',
    },
  });
  console.log('Created Admin user: admin@smart.edu / admin123');

  // 3. Create Department
  const csDept = await prisma.department.create({
    data: {
      name: 'Computer Science & Engineering',
      code: 'CSE',
    },
  });
  console.log('Created Department: CSE');

  // 4. Create Teachers
  const teacher1User = await prisma.user.create({
    data: {
      name: 'Dr. Rajesh Sharma',
      email: 'teacher1@smart.edu',
      passwordHash: teacherPass,
      role: 'TEACHER',
      status: 'ACTIVE',
    },
  });
  const teacher1 = await prisma.teacher.create({
    data: {
      userId: teacher1User.id,
      departmentId: csDept.id,
    },
  });

  const teacher2User = await prisma.user.create({
    data: {
      name: 'Prof. Priya Gupta',
      email: 'teacher2@smart.edu',
      passwordHash: teacherPass,
      role: 'TEACHER',
      status: 'ACTIVE',
    },
  });
  const teacher2 = await prisma.teacher.create({
    data: {
      userId: teacher2User.id,
      departmentId: csDept.id,
    },
  });
  console.log('Created 2 Teachers: teacher1@smart.edu, teacher2@smart.edu / teacher123');

  // 5. Create Courses
  const course1 = await prisma.course.create({
    data: {
      name: 'Introduction to Programming',
      code: 'CS101',
      departmentId: csDept.id,
    },
  });

  const course2 = await prisma.course.create({
    data: {
      name: 'Data Structures & Algorithms',
      code: 'CS201',
      departmentId: csDept.id,
    },
  });

  const course3 = await prisma.course.create({
    data: {
      name: 'Database Management Systems',
      code: 'CS301',
      departmentId: csDept.id,
    },
  });
  console.log('Created 3 Courses: CS101, CS201, CS301');

  // 6. Assign Teachers to Courses
  await prisma.teacherCourse.createMany({
    data: [
      { teacherId: teacher1.id, courseId: course1.id },
      { teacherId: teacher1.id, courseId: course2.id },
      { teacherId: teacher2.id, courseId: course3.id },
    ],
  });
  console.log('Assigned Teachers to Courses');

  // 7. Create 10 Students
  const studentData = [
    { name: 'Rahul Verma', email: 'student1@smart.edu', enrollmentNumber: 'CS2026001', semester: 4, section: 'A' },
    { name: 'Ananya Singh', email: 'student2@smart.edu', enrollmentNumber: 'CS2026002', semester: 4, section: 'A' },
    { name: 'Aarav Patel', email: 'student3@smart.edu', enrollmentNumber: 'CS2026003', semester: 4, section: 'A' },
    { name: 'Sneha Reddy', email: 'student4@smart.edu', enrollmentNumber: 'CS2026004', semester: 4, section: 'A' },
    { name: 'Vikram Joshi', email: 'student5@smart.edu', enrollmentNumber: 'CS2026005', semester: 4, section: 'A' },
    { name: 'Pooja Nair', email: 'student6@smart.edu', enrollmentNumber: 'CS2026006', semester: 4, section: 'B' },
    { name: 'Rohit Kumar', email: 'student7@smart.edu', enrollmentNumber: 'CS2026007', semester: 4, section: 'B' },
    { name: 'Divya Iyer', email: 'student8@smart.edu', enrollmentNumber: 'CS2026008', semester: 4, section: 'B' },
    { name: 'Kunal Shah', email: 'student9@smart.edu', enrollmentNumber: 'CS2026009', semester: 4, section: 'B' },
    { name: 'Neha Kapoor', email: 'student10@smart.edu', enrollmentNumber: 'CS2026010', semester: 4, section: 'B' },
  ];

  const createdStudents = [];
  for (const s of studentData) {
    const user = await prisma.user.create({
      data: {
        name: s.name,
        email: s.email,
        passwordHash: studentPass,
        role: 'STUDENT',
        status: 'ACTIVE',
      },
    });

    const student = await prisma.student.create({
      data: {
        userId: user.id,
        enrollmentNumber: s.enrollmentNumber,
        departmentId: csDept.id,
        semester: s.semester,
        section: s.section,
      },
    });

    createdStudents.push(student);

    // Enroll in all 3 courses
    await prisma.enrollment.createMany({
      data: [
        { studentId: student.id, courseId: course1.id, academicYear: '2025-2026' },
        { studentId: student.id, courseId: course2.id, academicYear: '2025-2026' },
        { studentId: student.id, courseId: course3.id, academicYear: '2025-2026' },
      ],
    });
  }
  console.log('Created 10 Students (student1@smart.edu - student10@smart.edu / student123) and enrolled them in all courses');

  // 8. Create Sample Past Attendance Sessions & Records for realistic dashboard metrics
  const now = new Date();
  for (let dayOffset = 5; dayOffset >= 1; dayOffset--) {
    const sessionDate = new Date(now);
    sessionDate.setDate(sessionDate.getDate() - dayOffset);
    sessionDate.setHours(10, 0, 0, 0);

    const session = await prisma.attendanceSession.create({
      data: {
        courseId: course1.id,
        teacherId: teacher1.id,
        sessionDate,
        startTime: sessionDate,
        endTime: new Date(sessionDate.getTime() + 50 * 60 * 1000),
        status: 'CLOSED',
      },
    });

    // Mark 8 out of 10 students present
    for (let i = 0; i < 8; i++) {
      await prisma.attendanceRecord.create({
        data: {
          sessionId: session.id,
          studentId: createdStudents[i].id,
          status: 'PRESENT',
          authMethod: 'QR_SCAN',
          timestamp: new Date(sessionDate.getTime() + (i + 1) * 30 * 1000),
        },
      });
    }
  }
  console.log('Created 5 past attendance sessions with records for demonstration');

  console.log('=============================================');
  console.log(' Database Seed Completed Successfully!');
  console.log(' Test Accounts:');
  console.log('   Admin:   admin@smart.edu    / admin123');
  console.log('   Teacher: teacher1@smart.edu / teacher123');
  console.log('   Student: student1@smart.edu / student123');
  console.log('=============================================');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
