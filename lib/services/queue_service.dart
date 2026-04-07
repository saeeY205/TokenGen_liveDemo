import 'dart:async';
export 'mock_database.dart';
import 'mock_database.dart';

class QueueService {
  // In-memory data
  static Map<String, dynamic> _mockSettings = {
    'isAcceptingTokens': true,
    'isPaused': false,
    'lastResetAt': DateTime.now(),
    'queueLimit': 0,
  };
  
  static final List<Map<String, dynamic>> _mockQueue = [
    {
      'tokenNumber': 1,
      'status': 'completed',
      'joinedAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'userId': 'user-1',
      'userName': 'Alice Smith',
      'ticketId': 't1'
    },
    {
      'tokenNumber': 2,
      'status': 'serving',
      'joinedAt': DateTime.now().subtract(const Duration(minutes: 15)),
      'userId': 'user-2',
      'userName': 'Bob Johnson',
      'ticketId': 't2'
    },
    {
      'tokenNumber': 3,
      'status': 'waiting',
      'joinedAt': DateTime.now().subtract(const Duration(minutes: 5)),
      'userId': 'user-3',
      'userName': 'Charlie Davis',
      'ticketId': 't3'
    },
  ];

  static final List<Map<String, dynamic>> _mockAnnouncements = [
    {
      'message': 'Welcome to TokenGen Demo!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
    }
  ];

  // Stream Controllers
  static final _settingsController = StreamController<DocumentSnapshot>.broadcast();
  static final _queueController = StreamController<QuerySnapshot>.broadcast();
  static final _announcementsController = StreamController<QuerySnapshot>.broadcast();

  // Helper to notify listeners
  void _notify() {
    _settingsController.add(DocumentSnapshot('queue_config', _mockSettings));
    _queueController.add(QuerySnapshot(
      _mockQueue.map((t) => QueryDocumentSnapshot(t['ticketId'], t)).toList(),
    ));
    _announcementsController.add(QuerySnapshot(
      _mockAnnouncements.map((a) => QueryDocumentSnapshot('ann-${DateTime.now().millisecondsSinceEpoch}', a)).toList(),
    ));
  }

  // Stream for global queue settings
  Stream<DocumentSnapshot> streamSettings() {
    Timer(Duration.zero, _notify);
    return _settingsController.stream;
  }

  // Update global queue settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    _mockSettings.addAll(settings);
    _notify();
  }

  // Join Queue
  Future<int> joinQueue(String userId, String userName) async {
    if (_mockSettings['isAcceptingTokens'] == false) {
      throw Exception('Queue is currently not accepting new tokens.');
    }

    int nextTokenNumber = 1;
    if (_mockQueue.isNotEmpty) {
      nextTokenNumber = _mockQueue.fold<int>(0, (max, t) => t['tokenNumber'] > max ? t['tokenNumber'] : max) + 1;
    }

    bool anyoneServing = _mockQueue.any((t) => t['status'] == 'serving');
    String initialStatus = anyoneServing ? 'waiting' : 'serving';

    final ticketId = 't-${DateTime.now().millisecondsSinceEpoch}';
    _mockQueue.add({
      'tokenNumber': nextTokenNumber,
      'status': initialStatus,
      'joinedAt': DateTime.now(),
      'userId': userId,
      'userName': userName,
      'ticketId': ticketId,
    });

    _notify();
    return nextTokenNumber;
  }

  // Call Next Student
  Future<void> callNextStudent() async {
    if (_mockSettings['isPaused'] == true) {
      throw Exception('Queue is paused. Resume to call students.');
    }

    // 1. Mark currently serving as completed
    for (var ticket in _mockQueue) {
      if (ticket['status'] == 'serving') ticket['status'] = 'completed';
    }

    // 2. Find next waiting
    final waiting = _mockQueue.where((t) => t['status'] == 'waiting').toList();
    waiting.sort((a, b) => a['tokenNumber'].compareTo(b['tokenNumber']));

    if (waiting.isNotEmpty) {
      waiting.first['status'] = 'serving';
    }

    _notify();
  }

  // Skip Ticket
  Future<void> skipTicket(String ticketId) async {
    final ticket = _mockQueue.firstWhere((t) => t['ticketId'] == ticketId);
    ticket['status'] = 'skipped';
    await callNextStudent();
  }

  // Reset Queue
  Future<void> resetQueue() async {
    _mockQueue.clear();
    _mockSettings.addAll({
      'isPaused': false,
      'isAcceptingTokens': true,
      'lastResetAt': DateTime.now(),
    });
    _notify();
  }

  // Stream for the full queue (Waiting + Serving)
  Stream<QuerySnapshot> streamQueue() {
    Timer(Duration.zero, _notify);
    return _queueController.stream;
  }

  // Stream for currently serving tickets
  Stream<QuerySnapshot> streamServing() {
    // Note: the real app expects QuerySnapshot
    Timer(Duration.zero, _notify);
    return _queueController.stream.map((s) => QuerySnapshot(
      s.docs.where((d) => d.data()['status'] == 'serving').toList()
    ));
  }

  // Stream for all tickets
  Stream<QuerySnapshot> streamAll() {
    Timer(Duration.zero, _notify);
    return _queueController.stream;
  }

  // Mark as done manual
  Future<void> markAsDone(String ticketId) async {
    final ticket = _mockQueue.firstWhere((t) => t['ticketId'] == ticketId);
    ticket['status'] = 'completed';
    _notify();
  }

  // Recall
  Future<void> recallTicket(String ticketId) async {
     _notify();
  }

  // Announcements
  Future<void> sendAnnouncement(String message) async {
    _mockAnnouncements.insert(0, {
      'message': message,
      'timestamp': DateTime.now(),
    });
    _notify();
  }

  Stream<QuerySnapshot> streamAnnouncements() {
    Timer(Duration.zero, _notify);
    return _announcementsController.stream;
  }

  // Waitlist methods (No-op in demo)
  Stream<QuerySnapshot> streamWaitlist() => const Stream.empty();
  Stream<DocumentSnapshot> streamMyWaitlistEntry(String uid) => const Stream.empty();
  Future<void> leaveWaitlist(String uid) async {}
  Future<void> joinWaitlist(String userId, String userName) async {}
}
