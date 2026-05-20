# EduConnect Flutter App — v2.0 Final

A fully functional, production-ready LMS Flutter app.

## Student Features
- Dashboard: greeting, stats, task checklist with toggle, course progress
- Course Detail: Announcements / Materials / Assignments / Grades / Discussion
- Assignments: submit with notes, view grade + teacher feedback
- Grades: average score, letter grade, per-assignment breakdown
- Chat: contact list, full conversation, send with read receipts
- Search, Notifications, Profile (edit name, change password)

## Teacher Features
- Dashboard: student count, pending grades, class average
- Course Detail: Create Post / Grade Work / Students / Schedule / Materials / Discussion
- Grading: slider 0-100, quick feedback chips, letter grade preview
- Students: search, filter (at risk / top performers), per-student detail + message
- Schedule: group by day, add with time picker + room + type + duration, delete
- Assignments: create with due date picker, view submissions
- Create Post: category chips, pin toggle

## Setup
```bash
flutter pub get
# Edit lib/services/api_service.dart → set baseUrl
flutter run
```

All screens fall back to mock data if API is unreachable.

