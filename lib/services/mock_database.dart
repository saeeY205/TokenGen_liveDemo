import 'dart:async';

class Timestamp {
  final DateTime _dateTime;
  Timestamp(this._dateTime);
  factory Timestamp.now() => Timestamp(DateTime.now());
  factory Timestamp.fromDate(DateTime date) => Timestamp(date);
  DateTime toDate() => _dateTime;
}

/// Compatibility classes to mimic Firebase Firestore behavior without the dependency.
/// Renamed to match Firebase types exactly to minimize UI changes.
class DocumentSnapshot {
  final String id;
  final Map<String, dynamic>? _data;
  DocumentSnapshot(this.id, this._data);
  Map<String, dynamic>? data() => _data;
  dynamic get(Object field) => _data?[field];
  bool get exists => _data != null;
  dynamic operator [](Object field) => _data?[field];
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  QueryDocumentSnapshot(super.id, super.data);
  @override
  Map<String, dynamic> data() => super.data() ?? {};
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

class User {
  final String uid;
  final String? email;
  final String? displayName;
  User({required this.uid, this.email, this.displayName});
  
  Future<void> updatePassword(String password) async {
    // No-op for demo
  }
}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}
