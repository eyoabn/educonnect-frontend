# EduConnect — Mobile Learning Management System

A full-stack Learning Management System (LMS) built with **Flutter** (frontend) and **Node.js/Express + MongoDB** (backend). Designed for universities and schools to manage courses, assignments, materials, real-time chat, and more.

## Team Members

| Name | Role | Branch |
|------|------|--------|
| Eyoab | Project Lead, Backend API & Integration | `eyoab/backend-api` |
| Fitsum | Authentication & User Management | `fitsum/auth-user` |
| Feysel | Course & Assignment System | `feysel/course-assignment` |
| Simret | Communication (Chat, Q&A, Notifications) | `simret/communication` |
| Yeabsira | UI/UX Design & Theming | `yeabsira/ui-theme` |

## Features

### Student
- **Dashboard** — Greeting, stats, task checklist, course progress cards
- **My Courses** — Browse enrolled courses with detailed sub-sections
- **Assignments** — View assignments, upload answers, track submission status
- **Materials** — Access uploaded course materials and documents
- **Chat** — Real-time messaging with teachers and classmates
- **Q&A Forum** — Ask and answer course-related questions
- **Notifications** — Stay updated on announcements and deadlines
- **Profile** — Edit name, change password, view account info

### Teacher
- **Dashboard** — Student count, pending tasks, class average overview
- **My Classes** — Manage courses with announcements, materials, assignments
- **Assignments** — Create assignments, track who submitted, view student answers
- **Students** — View enrolled students, search, filter by performance
- **Schedule** — Manage class schedules grouped by day
- **Create Post** — Post announcements with category and pin options
- **Chat** — Communicate with students directly

### Admin
- **User Management** — View and manage all users (teachers and students)
- **Course Management** — Oversee all courses in the system
- **System Statistics** — Dashboard with usage analytics

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Node.js, Express.js |
| Database | MongoDB with Mongoose ODM |
| Auth | JWT (JSON Web Tokens) |
| File Upload | Multer |
| State Management | Provider |
| HTTP Client | http package |

## Project Structure

```
educonnect-frontend/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/models.dart        # Data models (Course, User, etc.)
│   ├── services/
│   │   ├── api_service.dart      # API client + mock fallback
│   │   └── auth_provider.dart    # Authentication state management
│   ├── screens/                  # All app screens
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── layout_screen.dart
│   │   ├── course_detail_screen.dart
│   │   ├── assignments_screen.dart
│   │   ├── materials_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── qa_screen.dart
│   │   ├── announcements_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── student_list_screen.dart
│   │   ├── schedule_management_screen.dart
│   │   ├── search_screen.dart
│   │   ├── admin_screen.dart
│   │   ├── grading_screen.dart
│   │   ├── student_grades_screen.dart
│   │   └── create_post_screen.dart
│   ├── theme/app_theme.dart      # Colors, gradients, theme config
│   └── widgets/common_widgets.dart # Reusable UI components
└── pubspec.yaml

educonnect-backend/
├── server.js                     # Express server entry point
├── config/db.js                  # MongoDB connection
├── middleware/auth.js            # JWT authentication middleware
├── models/                       # Mongoose schemas
│   ├── User.js, Course.js, Grade.js, Material.js
│   ├── Message.js, Announcement.js, Notification.js
│   ├── Question.js, Schedule.js
├── controllers/                  # Business logic
│   ├── authController.js, adminController.js
│   ├── coursesController.js, gradesController.js
│   ├── materialsController.js, chatController.js
│   ├── announcementsController.js, qaController.js
│   ├── scheduleController.js, searchController.js
│   └── notificationsController.js
├── routes/                       # API route definitions
└── package.json
```

## Setup & Installation

### Prerequisites
- Flutter SDK (3.x+)
- Node.js (18+)
- MongoDB (local or Atlas)

### Backend
```bash
cd educonnect-backend
npm install
# Create .env file with MONGO_URI and JWT_SECRET
node server.js
```

### Frontend
```bash
cd educonnect-frontend
flutter pub get
# Edit lib/services/api_service.dart → set your backend URL
flutter run
```

> **Note:** The app includes mock data fallback — it works even without a running backend for demo purposes.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login and get JWT |
| GET | `/api/courses` | List all courses |
| GET | `/api/courses/:id` | Get course details |
| POST | `/api/grades/assignments` | Create assignment |
| PUT | `/api/grades/submit/:id` | Submit assignment answer |
| GET | `/api/grades/submissions/:courseId` | Get submissions |
| GET/POST | `/api/materials` | Course materials |
| GET/POST | `/api/announcements` | Announcements |
| GET/POST | `/api/chat` | Chat messages |
| GET/POST | `/api/qa` | Q&A forum |
| GET/POST | `/api/schedule` | Class schedule |

## License

This project was developed as a final group project for academic purposes.
