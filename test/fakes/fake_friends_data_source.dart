import 'package:new_project/resources_and_services/friends_data_source.dart';

/// An in-memory [FriendsDataSource] for tests, standing in for a real
/// Supabase project. Mirrors the bits of real Postgres/Supabase behavior
/// that matter for [NotesLogic][]'s tests: `updateFriendRequestStatus` and
/// `deleteFriendshipById` silently do nothing if the id doesn't match any
/// row, exactly like a real `.update()`/`.delete()` with no matching rows
/// would; `upsertFriendship` is a no-op if the pair already exists, matching
/// the real upsert's `onConflict` (accepting a friend request twice should
/// never create a second friendship row).
///
/// [NotesLogic]: ../../lib/resources_and_services/notes_logic.dart
class FakeFriendsDataSource implements FriendsDataSource {
  final List<Map<String, dynamic>> friendships = [];
  final List<Map<String, dynamic>> requests = [];
  int _nextFriendshipId = 1;
  int _nextRequestId = 1;

  @override
  String? currentUserId;

  @override
  Future<Map<String, dynamic>?> selectFriendshipByPair({
    required String lowId,
    required String highId,
  }) async {
    final index = friendships.indexWhere(
      (row) => row['user_low_id'] == lowId && row['user_high_id'] == highId,
    );
    if (index == -1) return null;
    return Map<String, dynamic>.from(friendships[index]);
  }

  @override
  Future<void> upsertFriendship({
    required String lowId,
    required String highId,
  }) async {
    final exists = friendships.any(
      (row) => row['user_low_id'] == lowId && row['user_high_id'] == highId,
    );
    if (exists) return;
    friendships.add({
      'id': 'friendship-${_nextFriendshipId++}',
      'user_low_id': lowId,
      'user_high_id': highId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> selectFriendshipsForUser(
    String userId,
  ) async {
    final matches = friendships
        .where(
          (row) =>
              row['user_low_id'] == userId || row['user_high_id'] == userId,
        )
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
    return matches;
  }

  @override
  Future<void> deleteFriendshipById(String friendshipId) async {
    friendships.removeWhere((row) => row['id'] == friendshipId);
  }

  @override
  Future<Map<String, dynamic>?> selectPendingRequestBetween({
    required String userA,
    required String userB,
  }) async {
    final index = requests.indexWhere((row) {
      if (row['status'] != 'pending') return false;
      final sender = row['sender_id'];
      final receiver = row['receiver_id'];
      return (sender == userA && receiver == userB) ||
          (sender == userB && receiver == userA);
    });
    if (index == -1) return null;
    return Map<String, dynamic>.from(requests[index]);
  }

  @override
  Future<void> insertFriendRequest(Map<String, dynamic> values) async {
    requests.add({
      'id': 'request-${_nextRequestId++}',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> selectPendingRequestsForReceiver(
    String userId,
  ) async {
    final matches = requests
        .where(
            (row) => row['receiver_id'] == userId && row['status'] == 'pending')
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
    return matches;
  }

  @override
  Future<List<Map<String, dynamic>>> selectPendingRequestsForSender(
    String userId,
  ) async {
    final matches = requests
        .where(
            (row) => row['sender_id'] == userId && row['status'] == 'pending')
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
    return matches;
  }

  @override
  Future<Map<String, dynamic>?> selectFriendRequestById(
    String requestId,
  ) async {
    final index = requests.indexWhere((row) => row['id'] == requestId);
    if (index == -1) return null;
    return Map<String, dynamic>.from(requests[index]);
  }

  @override
  Future<void> updateFriendRequestStatus(
    String requestId,
    String status,
  ) async {
    final index = requests.indexWhere((row) => row['id'] == requestId);
    if (index == -1) return;
    requests[index] = {...requests[index], 'status': status};
  }

  @override
  Future<int> countPendingRequestsForReceiver(String userId) async {
    return requests
        .where(
            (row) => row['receiver_id'] == userId && row['status'] == 'pending')
        .length;
  }
}
