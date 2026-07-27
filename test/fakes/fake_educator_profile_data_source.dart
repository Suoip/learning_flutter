import 'dart:typed_data';

import 'package:new_project/resources_and_services/educator_profile_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// An in-memory [EducatorProfileDataSource] for tests, standing in for a
/// real Supabase project. Mirrors the bits of real Postgres/Supabase
/// behavior that matter for [EducatorLogic][]'s tests: `updateEducatorById`
/// silently does nothing if the id doesn't match any row, exactly like a
/// real `.update()` with no matching rows would; `upsertEducator` replaces
/// an existing row with a matching id or inserts a new one, like a real
/// upsert.
///
/// [EducatorLogic]: ../../lib/resources_and_services/educator_logic.dart
class FakeEducatorProfileDataSource implements EducatorProfileDataSource {
  final List<Map<String, dynamic>> rows = [];
  final Map<String, Uint8List> uploadedAvatars = {};

  @override
  User? currentUser;

  @override
  Future<Map<String, dynamic>?> selectEducatorById(String id) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return null;
    return Map<String, dynamic>.from(rows[index]);
  }

  @override
  Future<Map<String, dynamic>?> selectEducatorByUsername(
    String username,
  ) async {
    final index = rows.indexWhere((row) => row['username'] == username);
    if (index == -1) return null;
    return Map<String, dynamic>.from(rows[index]);
  }

  @override
  Future<List<Map<String, dynamic>>> selectEducatorsByIds(
    List<String> ids,
  ) async {
    return rows
        .where((row) => ids.contains(row['id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<void> insertEducator(Map<String, dynamic> values) async {
    rows.add(Map<String, dynamic>.from(values));
  }

  @override
  Future<void> updateEducatorById(
    String id,
    Map<String, dynamic> values,
  ) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return;
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> upsertEducator(
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
  Future<String> uploadAvatarAndGetPublicUrl({
    required String objectPath,
    required Uint8List bytes,
  }) async {
    uploadedAvatars[objectPath] = bytes;
    return 'https://fake-storage.test/educator-avatars/$objectPath';
  }
}
