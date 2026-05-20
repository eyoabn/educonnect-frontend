import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Central API service – replace [baseUrl] with your actual backend URL.
class ApiService {
  // ─── CONFIG ────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://your-api.example.com/api';

  // ─── AUTH TOKEN ────────────────────────────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── GENERIC HELPERS ───────────────────────────────────────────────────────
  static Future<dynamic> _get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, res.body);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  static Future<dynamic> _delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return res.body.isNotEmpty ? jsonDecode(res.body) : null;
    }
    throw ApiException(res.statusCode, res.body);
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password, String role) async {
    final data = await _post(
      '/auth/login',
      {'email': email, 'password': password, 'role': role},
      auth: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token']);
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', data['name'] ?? '');
    return data;
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String name, String role) async {
    final data = await _post(
      '/auth/register',
      {'email': email, 'password': password, 'name': name, 'role': role},
      auth: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token']);
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', data['name'] ?? name);
    return data;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  // ─── COURSES ───────────────────────────────────────────────────────────────
  static Future<List<Course>> getCourses() async {
    final data = await _get('/courses');
    return (data as List).map((e) => Course.fromJson(e)).toList();
  }

  static Future<Course> getCourse(int id) async {
    final data = await _get('/courses/$id');
    return Course.fromJson(data);
  }

  // ─── ANNOUNCEMENTS ─────────────────────────────────────────────────────────
  static Future<List<Announcement>> getAnnouncements(int courseId) async {
    final data = await _get('/courses/$courseId/announcements');
    return (data as List).map((e) => Announcement.fromJson(e)).toList();
  }

  static Future<void> starAnnouncement(
      int courseId, int announcementId, bool starred) async {
    await _post(
      '/courses/$courseId/announcements/$announcementId/star',
      {'starred': starred},
    );
  }

  // ─── MATERIALS ─────────────────────────────────────────────────────────────
  static Future<List<StudyMaterial>> getMaterials(int courseId) async {
    final data = await _get('/courses/$courseId/materials');
    return (data as List).map((e) => StudyMaterial.fromJson(e)).toList();
  }

  static Future<String> getMaterialDownloadUrl(
      int courseId, int materialId) async {
    final data = await _get('/courses/$courseId/materials/$materialId/url');
    return data['url'];
  }

  // ─── CHAT ──────────────────────────────────────────────────────────────────
  static Future<List<ChatContact>> getContacts() async {
    final data = await _get('/chat/contacts');
    return (data as List).map((e) => ChatContact.fromJson(e)).toList();
  }

  static Future<List<ChatMessage>> getMessages(int contactId) async {
    final data = await _get('/chat/$contactId/messages');
    return (data as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<ChatMessage> sendMessage(int contactId, String content) async {
    final data = await _post(
      '/chat/$contactId/messages',
      {'content': content},
    );
    return ChatMessage.fromJson(data);
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────
  static Future<List<AppNotification>> getNotifications() async {
    final data = await _get('/notifications');
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<void> markNotificationRead(int id) async {
    await _post('/notifications/$id/read', {});
  }

  static Future<void> markAllNotificationsRead() async {
    await _post('/notifications/read-all', {});
  }

  static Future<void> deleteNotification(int id) async {
    await _delete('/notifications/$id');
  }

  // ─── SEARCH ────────────────────────────────────────────────────────────────
  static Future<List<SearchResult>> search(String query,
      {String filter = 'all'}) async {
    final data =
        await _get('/search?q=${Uri.encodeComponent(query)}&filter=$filter');
    return (data as List).map((e) => SearchResult.fromJson(e)).toList();
  }

  // ─── PROFILE ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    return await _get('/profile');
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await _post('/profile', data);
  }

  // ─── ADMIN ─────────────────────────────────────────────────────────────────
  // GET /api/admin/users?role=teacher   → List<{ id, name, email, role }>
  // GET /api/admin/users?role=student   → List<{ id, name, email, role }>
  // GET /api/admin/courses              → List<{ id, name, teacherId, teacherName, studentIds }>
  // POST /api/admin/courses/:id/teacher → { teacherId }
  // POST /api/admin/courses/:id/students → { studentIds: [...] }

  /// Fetch all users by role ('teacher' or 'student').
  static Future<List<Map<String, dynamic>>> adminGetUsersByRole(
      String role) async {
    final data = await _get('/admin/users?role=$role');
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Fetch all courses with teacher and student assignments.
  static Future<List<Map<String, dynamic>>> adminGetCourses() async {
    final data = await _get('/admin/courses');
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Assign a single teacher to a course.
  /// Backend: POST /api/admin/courses/:courseId/teacher
  /// Body:    { "teacherId": "..." }
  static Future<void> adminAssignTeacher(
      String courseId, String teacherId) async {
    await _post('/admin/courses/$courseId/teacher', {'teacherId': teacherId});
  }

  /// Set the full student enrolment list for a course.
  /// Backend: POST /api/admin/courses/:courseId/students
  /// Body:    { "studentIds": ["s1", "s2", ...] }
  static Future<void> adminAssignStudents(
      String courseId, List<String> studentIds) async {
    await _post(
        '/admin/courses/$courseId/students', {'studentIds': studentIds});
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
