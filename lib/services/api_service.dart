import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // ═══ BACKEND URL - CHANGE THIS BASED ON YOUR SETUP ═══
  // Use --dart-define=API_BASE_URL=https://your-backend.onrender.com/api when building.
  // For Android Emulator: use 'http://10.0.2.2:5000/api'
  // For Physical Device on same WiFi: use 'http://10.244.68.221:5000/api'
  // For Local Testing (Web/Dev): use 'http://localhost:5000/api'
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.244.68.221:5000/api',
  );
  
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  // ═══ TOKEN MANAGEMENT ═══
  static Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> _setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuth() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  static Future<bool> isAuthenticated() async {
    await _loadToken();
    return _token != null;
  }

  static Map<String, dynamic>? get currentUser => _currentUser;

  // ═══ AUTHENTICATION ═══
  
  /// Register new user - MUST DO THIS FIRST before login
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' or 'teacher'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final approved = data['user']?['approved'] != false;

        if (approved) {
          await _setToken(data['token'] ?? '');
          _currentUser = data['user'] ?? {};
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', jsonEncode(data['user'] ?? {}));
          await prefs.setString('user_role', role);
          await prefs.setString('user_email', email);
          await prefs.setString('user_name', name);
        }

        return {
          'success': true,
          'pending': !approved,
          'message': approved ? 'Account created successfully!' : 'Account created and pending admin approval.',
          'user': data['user'],
          'id': data['user']?['_id'] ?? '',
          'name': name,
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['msg'] ?? error['message'] ?? 'Registration failed',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Login user - ONLY works if user already registered
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _setToken(data['token'] ?? '');
        _currentUser = data['user'] ?? {};
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(data['user'] ?? {}));
        await prefs.setString('user_role', data['user']?['role'] ?? 'student');
        
        return {
          'success': true,
          'message': 'Login successful',
          'user': data['user'],
          'id': data['user']?['_id'] ?? '',
          'name': data['user']?['name'] ?? '',
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - likely pending approval
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['msg'] ?? error['message'] ?? 'Your account is pending admin approval',
            'pending': error['pending'] ?? true,
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Your account is pending admin approval',
            'pending': true,
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['msg'] ?? error['message'] ?? 'Invalid email or password',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  /// Logout user
  static Future<void> logout() async {
    await clearAuth();
  }

  // ═══ PROFILE ═══

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ COURSES ═══

  static Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/courses'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesList = List<Map<String, dynamic>>.from(data['courses'] ?? []);
        
        // Transform backend response to frontend format
        return coursesList.map((course) {
          final teacher = course['teacher'];
          final students = course['students'] ?? [];
          final pending = course['pending'] ?? [];
          
          return {
            'id': course['_id'] ?? '',
            'name': course['name'] ?? 'Course',
            'teacher': teacher is Map ? teacher['name'] ?? 'Unknown' : teacher.toString(),
            'gradientIndex': 0,
            'unread': 0,
            'progress': (course['progress'] ?? 0).toInt(),
            'students': students is List ? students.length : 0,
            'pending': pending is List ? pending.length : 0,
            'avgGrade': (course['avgGrade'] ?? 0).toInt(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminUsers(String role) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final url = Uri.parse('$baseUrl/admin/users${role.isNotEmpty ? '?role=$role' : ''}');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching admin users: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminCourses() async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/admin/courses'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesList = List<Map<String, dynamic>>.from(data['courses'] ?? []);
        return coursesList.map((course) {
          final teacher = course['teacher'];
          final students = List<Map<String, dynamic>>.from(course['students'] ?? []);

          return {
            'id': course['_id'] ?? '',
            'name': course['name'] ?? 'Course',
            'teacherId': teacher is Map ? (teacher['_id']?.toString() ?? teacher['id']?.toString()) : null,
            'teacherName': teacher is Map ? (teacher['name'] ?? teacher['email'] ?? null) : (teacher?.toString()),
            'studentIds': students
                .map((s) => (s['_id'] ?? s['id'] ?? s).toString())
                .where((v) => v.isNotEmpty)
                .toList(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching admin courses: $e');
      return [];
    }
  }

  /// Compatibility wrapper for admin_screen.dart.
  static Future<List<Map<String, dynamic>>> adminGetUsersByRole(String role) async {
    return getAdminUsers(role);
  }

  /// Compatibility wrapper for admin_screen.dart.
  static Future<List<Map<String, dynamic>>> adminGetCourses() async {
    return getAdminCourses();
  }

  /// Compatibility wrapper for admin_screen.dart.
  static Future<Map<String, dynamic>> adminAssignTeacher(
      String courseId,
      String teacherId,
  ) async {
    return adminAssignCourseTeacher(courseId: courseId, teacherId: teacherId);
  }

  /// Compatibility wrapper for admin_screen.dart.
  static Future<Map<String, dynamic>> adminAssignStudents(
      String courseId,
      List<String> studentIds,
  ) async {
    return adminAssignCourseStudents(courseId: courseId, studentIds: studentIds);
  }

  static Future<Map<String, dynamic>> adminApproveUser(String userId) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/approve'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to approve user'};
    } catch (e) {
      print('Error approving user: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminDeleteUser(String userId) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to delete user'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminAssignCourseTeacher({
    required String courseId,
    required String teacherId,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.put(
        Uri.parse('$baseUrl/admin/courses/$courseId/assign-teacher'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'teacherId': teacherId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to assign teacher'};
    } catch (e) {
      print('Error assigning teacher: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminAssignCourseStudents({
    required String courseId,
    required List<String> studentIds,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.put(
        Uri.parse('$baseUrl/admin/courses/$courseId/assign-students'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'studentIds': studentIds}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to assign students'};
    } catch (e) {
      print('Error assigning students: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCourse(String id) async {
    try {
      await _loadToken();
      if (_token == null) return {};

      final response = await http.get(
        Uri.parse('$baseUrl/courses/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final course = data['course'] ?? {};
        
        if (course.isEmpty) return {};
        
        final teacher = course['teacher'];
        final students = course['students'] ?? [];
        final pending = course['pending'] ?? [];
        
        return {
          'id': course['_id'] ?? '',
          'name': course['name'] ?? 'Course',
          'teacher': teacher is Map ? teacher['name'] ?? 'Unknown' : teacher.toString(),
          'gradientIndex': 0,
          'progress': (course['progress'] ?? 0).toInt(),
          'students': students is List ? students.length : 0,
          'studentsList': students is List ? students : [],
          'pending': pending is List ? pending.length : 0,
          'avgGrade': (course['avgGrade'] ?? 0).toInt(),
        };
      }
      return {};
    } catch (e) {
      print('Error fetching course: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/courses/search?q=$query'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCourse(String name) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/courses'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      print('Error creating course: $e');
      return {'success': false};
    }
  }

  // ═══ GRADES ═══
  
  static Future<List<Map<String, dynamic>>> getGrades(String studentId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/grades/student/$studentId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> gradeSubmission({
    required String submissionId,
    required int score,
    required String feedback,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final int? mockId = int.tryParse(submissionId);
      final String realId = (mockId != null ? _assignmentIdMap[mockId] : null) ?? submissionId;

      final response = await http.put(
        Uri.parse('$baseUrl/grades/grade/$realId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'score': score,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to grade'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ ANNOUNCEMENTS ═══
  
  static final Map<int, String> _announcementIdMap = {};

  static Future<List<Map<String, dynamic>>> getAnnouncements([dynamic courseId]) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final endpoint = courseId != null
        ? '$baseUrl/announcements/course/${courseId.toString()}'
        : '$baseUrl/announcements';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((a) {
          final map = a as Map<String, dynamic>;
          final String realId = map['_id']?.toString() ?? '';
          final int mockId = realId.hashCode.abs();
          _announcementIdMap[mockId] = realId;
          
          return {
            ...map,
            'id': mockId,
          };
        }).toList().cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> starAnnouncement({
    required String courseId,
    required int announcementId,
    required bool starred,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final String realId = _announcementIdMap[announcementId] ?? announcementId.toString();

      final response = await http.post(
        Uri.parse('$baseUrl/announcements/$realId/star'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'course': courseId, 'starred': starred}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    required String course,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'course': course,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'announcement': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to create'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ ASSIGNMENTS ═══

  static final Map<int, String> _assignmentIdMap = {};

  static Future<List<Map<String, dynamic>>> getAssignments(String studentId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/grades/student/$studentId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((g) {
          final String realId = g['_id']?.toString() ?? '';
          final int mockId = realId.hashCode.abs();
          _assignmentIdMap[mockId] = realId;

          DateTime? dateParsed;
          if (g['createdAt'] != null) {
            dateParsed = DateTime.tryParse(g['createdAt']);
          }
          final formattedDate = dateParsed != null 
              ? '${_getMonthName(dateParsed.month)} ${dateParsed.day}, ${dateParsed.year}'
              : 'Unknown';

          return {
            'id': mockId.toString(),
            'title': g['assignmentName'] as String? ?? 'Assignment',
            'course': g['course'] as String? ?? 'General Course',
            'due': formattedDate,
            'points': (g['maxGrade'] as num?)?.toInt() ?? 100,
            'status': g['status'] as String? ?? 'pending',
            'description': g['description'] as String? ?? '',
            'grade': (g['grade'] as num?)?.toInt(),
            'gi': mockId % 4,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error in getAssignments: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSubmissions(String courseId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/grades/course/$courseId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((g) {
          final String realId = g['_id']?.toString() ?? '';
          final int mockId = realId.hashCode.abs();
          _assignmentIdMap[mockId] = realId;

          final studentName = g['studentId'] != null && g['studentId'] is Map 
              ? (g['studentId']['name'] as String? ?? 'Unknown Student')
              : 'Student';

          DateTime? dateParsed;
          if (g['submittedDate'] != null) {
            dateParsed = DateTime.tryParse(g['submittedDate']);
          } else if (g['createdAt'] != null) {
            dateParsed = DateTime.tryParse(g['createdAt']);
          }
          final formattedDate = dateParsed != null 
              ? '${_getMonthName(dateParsed.month)} ${dateParsed.day}, ${dateParsed.year}'
              : 'Recently';

          return {
            'id': mockId.toString(),
            'student': studentName,
            'assignment': g['assignmentName'] as String? ?? 'Assignment',
            'course': g['course']?.toString() ?? '',
            'time': formattedDate,
            'gradientIndex': mockId % 4,
            'status': g['status'] as String? ?? 'pending',
            'grade': (g['grade'] as num?)?.toInt(),
            'feedback': g['feedback'] as String? ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error in getSubmissions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAssignment(
    String courseId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/grades/assignment'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course': courseId,
          ...data,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'assignment': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    required String content,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final String realId = _assignmentIdMap[assignmentId] ?? assignmentId.toString();

      final response = await http.put(
        Uri.parse('$baseUrl/grades/submit/$realId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'submission': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to submit'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ MATERIALS ═══
  
  static final Map<int, String> _materialIdMap = {};

  static Future<List<Map<String, dynamic>>> getMaterials(String courseId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/materials/course/$courseId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((m) {
          final title = m['title'] as String? ?? 'Material';
          final ext = title.split('.').last.toUpperCase();
          final type = (ext == 'PDF' || ext == 'DOC' || ext == 'DOCX' || ext == 'XLS' || ext == 'XLSX') ? ext : 'FILE';
          
          DateTime? dateParsed;
          if (m['uploadedDate'] != null) {
            dateParsed = DateTime.tryParse(m['uploadedDate']);
          }
          final formattedDate = dateParsed != null 
              ? '${_getMonthName(dateParsed.month)} ${dateParsed.day}, ${dateParsed.year}'
              : 'Unknown';

          final String realId = m['_id']?.toString() ?? '';
          final int mockId = realId.hashCode.abs();
          _materialIdMap[mockId] = realId;

          return {
            'id': mockId,
            'name': title,
            'type': type,
            'size': '2.5 MB',
            'date': formattedDate,
            'category': m['category'] ?? 'lecture',
            'downloaded': false,
            'version': m['version'] ?? 1,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error in getMaterials: $e');
      return [];
    }
  }

  static String _getMonthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'Jan';
  }

  static Future<Map<String, dynamic>> uploadMaterial({
    required String courseId,
    required String title,
    required String url,
    String? category,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/materials'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course': courseId,
          'title': title,
          'url': url,
          'category': category ?? 'lecture',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMaterialDownloadUrl(String courseId, int materialId) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false, 'url': ''};

      final String realId = _materialIdMap[materialId] ?? materialId.toString();

      final response = await http.get(
        Uri.parse('$baseUrl/materials/$realId/download'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url'] ?? ''};
      }
      return {'success': false, 'url': ''};
    } catch (e) {
      return {'success': false, 'url': ''};
    }
  }

  static Future<Map<String, dynamic>> deleteMaterial(String courseId, int materialId) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final String realId = _materialIdMap[materialId] ?? materialId.toString();

      final response = await http.delete(
        Uri.parse('$baseUrl/materials/$realId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateMaterialVersion({
    required String materialId,
    required String fileUrl,
    String? description,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final int? mockId = int.tryParse(materialId);
      final String realId = (mockId != null ? _materialIdMap[mockId] : null) ?? materialId;

      final response = await http.put(
        Uri.parse('$baseUrl/materials/$realId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fileUrl': fileUrl,
          if (description != null) 'description': description,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ Q&A FORUM ═══

  static Future<List<Question>> getQuestions(String courseId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/qa/course/$courseId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((q) => Question.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createQuestion({
    required String courseId,
    required String title,
    required String content,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/qa'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'courseId': courseId,
          'title': title,
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> postAnswer({
    required String questionId,
    required String content,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/qa/$questionId/answers'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ CHAT ═══
  
  static Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/chat/contacts'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversation/$conversationId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    required String text,
  }) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ SCHEDULE ═══

  static Future<List<Map<String, dynamic>>> getSchedule({required String courseId}) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/schedule/course/$courseId'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createScheduleItem(
    String courseId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course': courseId,
          ...data,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteScheduleItem(String courseId, int id) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.delete(
        Uri.parse('$baseUrl/schedule/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══ NOTIFICATIONS ═══

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      await _loadToken();
      if (_token == null) return {'success': false};

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  // ═══ SEARCH ═══

  static Future<List<SearchResult>> search(String query, {String? filter}) async {
    try {
      await _loadToken();
      if (_token == null) return [];

      final url = filter != null 
        ? '$baseUrl/search?q=$query&filter=$filter'
        : '$baseUrl/search?q=$query';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final items = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        return items.map((item) => SearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
