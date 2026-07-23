import 'dart:typed_data';

import 'package:new_project/resources_and_services/profiles_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// An in-memory [ProfilesDataSource] for tests, standing in for a real
/// Supabase project. Mirrors the bits of real Postgres/Supabase behavior
/// that matter for [NotesLogic][]'s tests: `updateProfileById` silently does
/// nothing if the id doesn't match any row, exactly like a real `.update()`
/// with no matching rows would; `upsertProfile` replaces an existing row
/// with a matching id or inserts a new one, like a real upsert.
///
/// [NotesLogic]: ../../lib/resources_and_services/notes_logic.dart
class FakeProfilesDataSource implements ProfilesDataSource {
  final List<Map<String, dynamic>> rows = [];
  final Map<String, Uint8List> uploadedAvatars = {};

  @override
  User? currentUser;

  @override
  Future<Map<String, dynamic>?> selectProfileById(String userId) async {
    final index = rows.indexWhere((row) => row['id'] == userId);
    if (index == -1) return null;
    return Map<String, dynamic>.from(rows[index]);
  }

  @override
  Future<Map<String, dynamic>?> selectProfileByUsername(String username) async {
    final index = rows.indexWhere((row) => row['username'] == username);
    if (index == -1) return null;
    return Map<String, dynamic>.from(rows[index]);
  }

  @override
  Future<List<Map<String, dynamic>>> selectProfilesByIds(
    List<String> ids,
  ) async {
    return rows
        .where((row) => ids.contains(row['id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<void> insertProfile(Map<String, dynamic> values) async {
    rows.add(Map<String, dynamic>.from(values));
  }

  @override
  Future<void> updateProfileById(
    String userId,
    Map<String, dynamic> values,
  ) async {
    final index = rows.indexWhere((row) => row['id'] == userId);
    if (index == -1) return;
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> upsertProfile(
    Map<String, dynamic> values, {
    required String onConflict,
  }) async {
    final index = rows.indexWhere((row) => row['id'] == values['id']);
    if (index == -1) {
      rows.add(Map<String, dynamic>.from(values));
    } else {
      rows[index] = {...rows[index], ...values};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchProfilesByUsername({
    required String query,
    required String excludeUserId,
    int limit = 20,
  }) async {
    final normalized = query.toLowerCase();
    final matches = rows.where((row) {
      if (row['id'] == excludeUserId) return false;
      final username = (row['username'] ?? '').toString().toLowerCase();
      return username.contains(normalized);
    }).toList()
      ..sort(
        (a, b) => (a['username'] ?? '')
            .toString()
            .compareTo((b['username'] ?? '').toString()),
      );

    return matches
        .take(limit)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<String> uploadAvatarAndGetPublicUrl({
    required String objectPath,
    required Uint8List bytes,
  }) async {
    uploadedAvatars[objectPath] = bytes;
    return 'https://fake-storage.test/profile-pictures/$objectPath';
  }
}
