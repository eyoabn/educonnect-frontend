# EduConnect — Admin Panel Integration Guide

## What's in this package

| File | Action |
|------|--------|
| `admin_screen.dart` | **NEW** — drop into `lib/screens/` |
| `api_service.dart` | **REPLACE** `lib/services/api_service.dart` — adds 4 admin methods at the bottom, all else unchanged |
| `auth_provider.dart` | **REPLACE** `lib/services/auth_provider.dart` — adds `bool get isAdmin => _role == 'admin'`, all else unchanged |
| `layout_screen.dart` | **REPLACE** `lib/screens/layout_screen.dart` — admin branch in `build()`, admin-only bottom nav |
| `login_screen_patch.dart` | **REPLACE** `lib/screens/login_screen.dart` (rename the file) — adds Admin role button |

---

## Integration steps

```bash
# 1. Copy admin_screen into your screens folder
cp admin_screen.dart  <your-project>/lib/screens/admin_screen.dart

# 2. Replace the three modified files
cp api_service.dart   <your-project>/lib/services/api_service.dart
cp auth_provider.dart <your-project>/lib/services/auth_provider.dart
cp layout_screen.dart <your-project>/lib/screens/layout_screen.dart

# 3. Replace login screen (optional — only needed if you want the Admin role button)
cp login_screen_patch.dart <your-project>/lib/screens/login_screen.dart

# 4. Run
flutter pub get && flutter run
```

> No `pubspec.yaml` changes needed — admin panel uses only packages already in your project.

---

## Admin panel features

### Courses tab
- Lists every course with its assigned teacher and enrolled student count
- Stacked avatar previews of enrolled students (up to 3 + overflow counter)
- **Assign / Change Teacher** → opens a searchable single-select bottom sheet
- **Enrol / Manage Students** → opens a multi-select bottom sheet with Select All, search, live counter

### Teachers tab
- Full list of all teacher accounts
- Live search by name or email

### Students tab
- Full list of all student accounts
- Live search by name or email

### Header stats bar
- Courses · Teachers · Students · Unassigned (highlighted orange when > 0)
- Refresh button to re-fetch all data

### Offline / dev mode
All data falls back to realistic mock data when the API is unreachable, so the UI is fully interactive without a live backend.

---

## Backend API contract (admin endpoints only)

The four new methods in `ApiService` expect:

```
GET  /api/admin/users?role=teacher
     → [ { id, name, email, role }, ... ]

GET  /api/admin/users?role=student
     → [ { id, name, email, role }, ... ]

GET  /api/admin/courses
     → [ { id, name, teacherId, teacherName, studentIds: [...] }, ... ]

POST /api/admin/courses/:courseId/teacher
     Body: { "teacherId": "string" }
     → 200 OK

POST /api/admin/courses/:courseId/students
     Body: { "studentIds": ["s1", "s2", ...] }
     → 200 OK
```

All admin endpoints must be protected by a middleware that checks `role === 'admin'` on the JWT.

---

## Role routing summary

| Role | Bottom nav tabs | First screen |
|------|----------------|--------------|
| `student` | Home · Chat · Search · Alerts · Profile | Dashboard |
| `teacher` | Home · Students · Grade · Alerts · Profile | Dashboard |
| `admin` | Admin · Profile | Admin Panel |

The admin sees **only** the Admin panel and Profile tabs — no student/teacher content.
