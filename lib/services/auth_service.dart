import 'dart:async';
export 'mock_database.dart';
import 'mock_database.dart';

class AuthService {
  // In-memory current user
  static User? _currentUser;
  
  // Storage for demo users
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin-123': {
      'name': 'Admin User',
      'prn': 'ADMIN001',
      'email': 'admin@gmail.com',
      'role': 'admin',
    },
    'student-123': {
      'name': 'Demo Student',
      'prn': '12345678',
      'phoneNumber': '9876543210',
      'year': '3rd Year',
      'role': 'student',
    }
  };

  User? get currentUser => _currentUser;

  Stream<User?> get authStateChanges {
    final controller = StreamController<User?>();
    Timer(Duration.zero, () => controller.add(_currentUser));
    return controller.stream;
  }

  Future<UserCredential> signUpStudent({
    required String name,
    required String prn,
    required String phoneNumber,
    required String year,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final uid = 'user-${DateTime.now().millisecondsSinceEpoch}';
    _mockUsers[uid] = {
      'name': name,
      'prn': prn,
      'phoneNumber': phoneNumber,
      'year': year,
      'role': 'student',
      'createdAt': DateTime.now(),
    };
    _currentUser = User(uid: uid, email: '$prn@student.com');
    return UserCredential(user: _currentUser);
  }

  Future<UserCredential> signInStudentWithEmail({
    required String prn,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simple check: iterate users for matching PRN
    String? foundUid;
    _mockUsers.forEach((uid, data) {
      if (data['prn'] == prn) foundUid = uid;
    });

    if (foundUid != null) {
      _currentUser = User(uid: foundUid!, email: '$prn@student.com');
      return UserCredential(user: _currentUser);
    } else {
      // For demo, just create a user if not found
      return signUpStudent(
        name: 'Guest Student', 
        prn: prn, 
        phoneNumber: '0000000000', 
        year: '1st Year', 
        password: password
      );
    }
  }

  Future<UserCredential> signInAdmin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (email == 'admin@gmail.com' && password == '12345') {
      _currentUser = User(uid: 'admin-123', email: email);
      return UserCredential(user: _currentUser);
    }
    throw Exception('Invalid admin credentials');
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<void> changePassword(String newPassword) async {
    // No-op
  }

  Future<void> updateUserYear(String userId, String year) async {
    if (_mockUsers.containsKey(userId)) {
      _mockUsers[userId]!['year'] = year;
    }
  }

  Stream<DocumentSnapshot> getUserData(String userId) {
    final controller = StreamController<DocumentSnapshot>();
    Timer(Duration.zero, () {
      controller.add(DocumentSnapshot(userId, _mockUsers[userId]));
    });
    return controller.stream;
  }
}
