import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseQuery implements Future<List<Map<String, dynamic>>> {
  MockSupabaseQuery(String table, List<Map<String, dynamic>>? rows)
      : _rows = rows ?? [];

  final List<Map<String, dynamic>> _rows;
  final Map<String, dynamic> _eqConditions = {};
  Map<String, dynamic>? _updateData;
  Map<String, dynamic>? _upsertData;

  List<Map<String, dynamic>> get _filtered {
    var results = List<Map<String, dynamic>>.from(_rows);
    for (final e in _eqConditions.entries) {
      results = results.where((r) => r[e.key] == e.value).toList();
    }
    if (_updateData != null && results.isNotEmpty) {
      results = results.map((r) => {...r, ..._updateData!}).toList();
    }
    if (_upsertData != null) {
      results = [{..._upsertData!}];
    }
    return results;
  }

  MockSupabaseQuery select([String columns = '*']) => this;

  MockSupabaseQuery eq(String column, dynamic value) {
    _eqConditions[column] = value;
    return this;
  }

  MockSupabaseQuery order(String column, {bool ascending = true}) => this;

  MockSupabaseQuery update(Map<String, dynamic> data) {
    _updateData = data;
    return this;
  }

  MockSupabaseQuery upsert(Map<String, dynamic> data, {String? onConflict}) {
    _upsertData = data;
    return this;
  }

  Future<Map<String, dynamic>?> maybeSingle() async {
    final f = _filtered;
    return f.isEmpty ? null : f.first;
  }

  Future<Map<String, dynamic>> single() async => _filtered.first;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) =>
      Future.value(_filtered).then(
        onValue,
        onError: onError as FutureOr<R> Function(Object, StackTrace)?,
      );

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) =>
      Future.value(_filtered).catchError(onError, test: test);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) =>
      Future.value(_filtered).whenComplete(action);

  @override
  Stream<List<Map<String, dynamic>>> asStream() =>
      Future.value(_filtered).asStream();

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) =>
      Future.value(_filtered).timeout(timeLimit, onTimeout: onTimeout);
}

class MockSupabaseAuth {
  Session? _currentSession;
  User? _currentUser;
  final _stateController = StreamController<AuthState>.broadcast();

  MockSupabaseAuth({Session? session, User? user})
      : _currentSession = session,
        _currentUser = user;

  Session? get currentSession => _currentSession;
  User? get currentUser => _currentUser;
  Stream<AuthState> get onAuthStateChange => _stateController.stream;

  Future<AuthResponse> signInWithOtp({String? phone, String? email}) async {
    return AuthResponse(session: null, user: null);
  }

  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return AuthResponse(session: _currentSession, user: _currentUser);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return AuthResponse(session: _currentSession, user: _currentUser);
  }

  Future<void> signOut({Object? scope}) async {
    _currentSession = null;
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSupabaseClient {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final MockSupabaseAuth _auth;

  MockSupabaseClient({Session? session, User? user})
      : _auth = MockSupabaseAuth(session: session, user: user);

  MockSupabaseAuth get auth => _auth;

  MockSupabaseQuery from(String table) {
    return MockSupabaseQuery(table, _tables[table]);
  }

  void addRow(String table, Map<String, dynamic> row) {
    _tables.putIfAbsent(table, () => []);
    _tables[table]!.add(row);
  }

  void setRows(String table, List<Map<String, dynamic>> rows) {
    _tables[table] = rows;
  }
}
