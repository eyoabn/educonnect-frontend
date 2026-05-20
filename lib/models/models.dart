// ── models/models.dart ─────────────────────────────────────────────────────

class Course {
  final String id;
  final String name;
  final String teacher;
  final int gradientIndex;
  final int unread;
  final int progress;
  final int? students;
  final int? pending;
  final int? avgGrade;

  Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.gradientIndex,
    this.unread = 0,
    this.progress = 0,
    this.students,
    this.pending,
    this.avgGrade,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
    name: j['name'],
    teacher: j['teacher'] ?? '',
    gradientIndex: j['gradientIndex'] ?? 0,
    unread: j['unread'] ?? 0,
    progress: j['progress'] ?? 0,
    students: j['students'],
    pending: j['pending'],
    avgGrade: j['avgGrade'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'teacher': teacher,
    'gradientIndex': gradientIndex, 'unread': unread,
    'progress': progress, 'students': students,
    'pending': pending, 'avgGrade': avgGrade,
  };
}

class Announcement {
  final int id;
  final String author;
  final String title;
  final String content;
  final String timestamp;
  final String date;
  final String category;
  final bool pinned;
  bool starred;

  Announcement({
    required this.id, required this.author, required this.title,
    required this.content, required this.timestamp, required this.date,
    required this.category, this.pinned = false, this.starred = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id'], author: j['author'], title: j['title'],
    content: j['content'], timestamp: j['timestamp'], date: j['date'],
    category: j['category'], pinned: j['pinned'] ?? false, starred: j['starred'] ?? false,
  );
}

class StudyMaterial {
  final int id;
  final String name;
  final String type;
  final String size;
  final String date;
  final String category;
  bool downloaded;
  final String? url;
  final int version;

  StudyMaterial({
    required this.id, required this.name, required this.type,
    required this.size, required this.date, required this.category,
    this.downloaded = false, this.url, this.version = 1,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> j) => StudyMaterial(
    id: j['id'], name: j['name'], type: j['type'],
    size: j['size'], date: j['date'], category: j['category'],
    downloaded: j['downloaded'] ?? false, url: j['url'],
    version: j['version'] ?? 1,
  );
}

class ChatContact {
  final int id;
  final String name;
  final String role;
  final String avatar;
  final bool online;
  int unread;
  String lastMessage;
  final int gradientIndex;

  ChatContact({
    required this.id, required this.name, required this.role,
    required this.avatar, required this.online, required this.unread,
    required this.lastMessage, required this.gradientIndex,
  });

  factory ChatContact.fromJson(Map<String, dynamic> j) => ChatContact(
    id: j['id'], name: j['name'], role: j['role'],
    avatar: j['avatar'], online: j['online'] ?? false,
    unread: j['unread'] ?? 0, lastMessage: j['lastMessage'] ?? '',
    gradientIndex: j['gradientIndex'] ?? 0,
  );
}

class ChatMessage {
  final int id;
  final String sender;
  final String content;
  final String time;
  final bool isSelf;
  final MessageStatus status;

  ChatMessage({
    required this.id, required this.sender, required this.content,
    required this.time, required this.isSelf,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'], sender: j['sender'], content: j['content'],
    time: j['time'], isSelf: j['isSelf'] ?? false,
  );
}

enum MessageStatus { sending, sent, delivered, read }

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String description;
  final String time;
  bool read;

  AppNotification({
    required this.id, required this.type, required this.title,
    required this.description, required this.time, this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'], type: j['type'], title: j['title'],
    description: j['description'], time: j['time'], read: j['read'] ?? false,
  );
}

class SearchResult {
  final int id;
  final String type;
  final String title;
  final String? course;
  final String? teacher;
  final String match;

  SearchResult({
    required this.id, required this.type, required this.title,
    this.course, this.teacher, required this.match,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    id: j['id'], type: j['type'], title: j['title'],
    course: j['course'], teacher: j['teacher'], match: j['match'],
  );
}

class UpcomingTask {
  final int id;
  final String title;
  final String due;
  final String priority;
  bool completed;

  UpcomingTask({
    required this.id, required this.title,
    required this.due, required this.priority, this.completed = false,
  });

  factory UpcomingTask.fromJson(Map<String, dynamic> j) => UpcomingTask(
    id: j['id'], title: j['title'], due: j['due'],
    priority: j['priority'], completed: j['completed'] ?? false,
  );
}

class ScheduleItem {
  final int id;
  final String time;
  final String className;
  final String room;
  final String type;
  final String? day;
  final int? duration;

  ScheduleItem({
    required this.id, required this.time, required this.className,
    required this.room, required this.type, this.day, this.duration,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
    id: j['id'], time: j['time'], className: j['className'] ?? j['class'] ?? '',
    room: j['room'], type: j['type'], day: j['day'], duration: j['duration'],
  );
}

class Submission {
  final int id;
  final String student;
  final String assignment;
  final String course;
  final String time;
  final int gradientIndex;
  String status;
  int? grade;
  String? feedback;

  Submission({
    required this.id, required this.student, required this.assignment,
    required this.course, required this.time, required this.gradientIndex,
    this.status = 'pending', this.grade, this.feedback,
  });

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
    id: j['id'], student: j['student'], assignment: j['assignment'],
    course: j['course'], time: j['time'],
    gradientIndex: j['gradientIndex'] ?? 0,
    status: j['status'] ?? 'pending',
    grade: j['grade'], feedback: j['feedback'],
  );
}

class GradeRecord {
  final String studentId;
  final String studentName;
  final String assignment;
  final int grade;
  final String feedback;
  final DateTime gradedAt;

  GradeRecord({
    required this.studentId, required this.studentName,
    required this.assignment, required this.grade,
    required this.feedback, required this.gradedAt,
  });
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final Map<String, dynamic> stats;

  UserProfile({
    required this.id, required this.name, required this.email,
    required this.role, this.avatarUrl, required this.stats,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'].toString(), name: j['name'], email: j['email'],
    role: j['role'], avatarUrl: j['avatarUrl'],
    stats: j['stats'] ?? {},
  );
}

class Answer {
  final String id;
  final String authorName;
  final String content;
  final String timestamp;

  Answer({
    required this.id, required this.authorName,
    required this.content, required this.timestamp,
  });

  factory Answer.fromJson(Map<String, dynamic> j) => Answer(
    id: j['_id']?.toString() ?? '',
    authorName: j['authorName'] ?? 'Unknown',
    content: j['content'] ?? '',
    timestamp: j['timestamp']?.toString() ?? '',
  );
}

class Question {
  final String id;
  final String authorName;
  final String title;
  final String content;
  final String createdAt;
  final List<Answer> answers;

  Question({
    required this.id, required this.authorName, required this.title,
    required this.content, required this.createdAt, required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['_id']?.toString() ?? '',
    authorName: j['authorName'] ?? 'Unknown',
    title: j['title'] ?? '',
    content: j['content'] ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
    answers: (j['answers'] as List?)?.map((a) => Answer.fromJson(a)).toList() ?? [],
  );
}
