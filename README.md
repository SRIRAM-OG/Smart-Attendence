<<<<<<< HEAD
# Smart Attendance App — Architecture & Getting Started

Smart Attendance App is an enterprise-grade digital attendance solution using dynamic time-limited **QR Codes** and role-based authentication (Students, Teachers, Administrators).

---

## 🏛 Project Structure

```
SmartAttendanceApp/
├── backend/                      # Node.js + Express + Prisma REST API
│   ├── prisma/
│   │   ├── schema.prisma         # 9-table relational database schema
│   │   └── seed.js               # Demo dataset seeder
│   ├── src/
│   │   ├── index.js              # Server entry point
│   │   ├── config/               # Database & client singletons
│   │   ├── controllers/          # Request handlers for Auth, Attendance, Reports, Admin
│   │   ├── middleware/           # JWT verification, RBAC, Joi validation, error handling
│   │   ├── routes/               # API endpoints (/api/auth, /api/attendance, /api/admin, etc.)
│   │   ├── services/             # QR signing/validation, business logic, analytics
│   │   ├── utils/                # JWT, bcrypt hashing, ApiError
│   │   └── validators/           # Joi schemas
│   └── tests/                    # Jest automated test suites
│
└── flutter_app/                  # Flutter Mobile App (Android & iOS)
    ├── lib/
    │   ├── main.dart             # App entry with MultiProvider
    │   ├── app.dart              # MaterialApp.router with Material 3 Theme
    │   ├── config/               # API URLs, routes, theme constants
    │   ├── models/               # User, Student, Course, Session, Record data models
    │   ├── providers/            # State management (Auth, Attendance, Course)
    │   ├── screens/
    │   │   ├── auth/             # Login & Student Registration screens
    │   │   ├── student/          # Dashboard, Camera QR Scanner, History, Profile
    │   │   ├── teacher/          # Dashboard, Session Creator, QR Presenter, Monitor, Reports
    │   │   └── admin/            # Console, Student/Teacher/Course Managers, Defaulter Reports
    │   ├── services/             # Dio HTTP client with JWT interceptors, secure storage
    │   └── widgets/              # Reusable percentage indicators, stat cards, tiles
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### 1. Backend Setup

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env

# 3. Generate Prisma client & push schema
npx prisma generate
npx prisma db push

# 4. Seed database with demo accounts & realistic attendance history
node prisma/seed.js

# 5. Start API Server (runs on http://localhost:3000)
npm run dev
```

### 2. Pre-seeded Demo Accounts

| Role | Email | Password | Details |
|------|-------|----------|---------|
| **Administrator** | `admin@smart.edu` | `admin123` | Full system access & reports |
| **Teacher** | `teacher1@smart.edu` | `teacher123` | Dr. Rajesh Sharma (CS101, CS201) |
| **Teacher** | `teacher2@smart.edu` | `teacher123` | Prof. Priya Gupta (CS301) |
| **Student** | `student1@smart.edu` | `student123` | Rahul Verma (Roll: CS2026001) |
| **Student** | `student2@smart.edu` | `student123` | Ananya Singh (Roll: CS2026002) |
| **Student** | `student3@smart.edu` - `student10@smart.edu` | `student123` | Batch of 10 students |

---

### 3. Flutter Mobile App Setup

```bash
cd flutter_app

# 1. Get dependencies
flutter pub get

# 2. Run on Android Emulator or physical device
flutter run
```

---

## 🛡 Attendance Security Features
1. **Dynamic Cryptographic QR Codes**: QR codes contain short-lived random UUIDs with SHA-256 HMAC signatures.
2. **Strict Expiry**: QR tokens automatically expire in 1–15 minutes (configurable by teacher).
3. **Duplicate Prevention**: Database compound unique constraints `(sessionId, studentId)` strictly prevent multiple attendance submissions.
4. **Course Enrollment Verification**: Students cannot mark attendance for courses they are not officially enrolled in.
5. **Real-time Live Polling**: Teachers see student check-ins updating in real time.
=======
# Smart-Attendence
Smart Attendance App is a modern attendance management system that simplifies student attendance tracking, record management, and monitoring. It provides an intuitive dashboard for managing students, subjects, attendance records, and attendance statistics with a responsive and user-friendly interface.
>>>>>>> 3043feb7bf12bae248da42b767e151b105185f42
