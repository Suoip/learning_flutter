import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [NotesLogic][] needs for friend requests and
/// friendships, kept separate from `SupabaseClient` for the same reason as
/// [NotesDataSource][]: tests substitute an in-memory fake instead of a real
/// Supabase project.
///
/// [NotesLogic]: notes_logic.dart
/// [NotesDataSource]: notes_data_source.dart
abstract class FriendsDataSource {
  /// The currently authenticated user's id, or null if signed out. Every
  /// friends operation only ever needs the id, not the full [User] (unlike
  /// [ProfilesDataSource.currentUser]).
  String? get currentUserId;

  Future<Map<String, dynamic>?> selectFriendshipByPair({
    required String lowId,
    required String highId,
  });

  Future<void> upsertFriendship({
    required String lowId,
    required String highId,
  });

  Future<List<Map<String, dynamic>>> selectFriendshipsForUser(String userId);

  Future<void> deleteFriendshipById(String friendshipId);

  Future<Map<String, dynamic>?> selectPendingRequestBetween({
    required String userA,
    required String userB,
  });

  Future<void> insertFriendRequest(Map<String, dynamic> values);

  Future<List<Map<String, dynamic>>> selectPendingRequestsForReceiver(
    String userId,
  );

  Future<List<Map<String, dynamic>>> selectPendingRequestsForSender(
    String userId,
  );

  Future<Map<String, dynamic>?> selectFriendRequestById(String requestId);

  Future<void> updateFriendRequestStatus(String requestId, String status);

  Future<int> countPendingRequestsForReceiver(String userId);
}

/// The real [FriendsDataSource], backed by a Supabase project.
class SupabaseFriendsDataSource implements FriendsDataSource {
  SupabaseFriendsDataSource(this._client);

  final SupabaseClient _client;

  static const _friendshipsTable = 'friendships';
  static const _requestsTable = 'friend_requests';
  static const _friendshipColumns = 'id,user_low_id,user_high_id,created_at';
  static const _requestColumns = 'id,sender_id,receiver_id,status,created_at';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> selectFriendshipByPair({
    required String lowId,
    required String highId,
  }) {
    return _client
        .from(_friendshipsTable)
        .select('id')
        .eq('user_low_id', lowId)
        .eq('user_high_id', highId)
        .maybeSingle();
  }

  @override
  Future<void> upsertFriendship({
    required String lowId,
    required String highId,
  }) async {
    await _client.from(_friendshipsTable).upsert({
      'user_low_id': lowId,
      'user_high_id': highId,
    }, onConflict: 'user_low_id,user_high_id');
  }

  @override
  Future<List<Map<String, dynamic>>> selectFriendshipsForUser(
    String userId,
  ) async {
    final rows = await _client
        .from(_friendshipsTable)
        .select(_friendshipColumns)
        .or('user_low_id.eq.$userId,user_high_id.eq.$userId')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> deleteFriendshipById(String friendshipId) async {
    await _client.from(_friendshipsTable).delete().eq('id', friendshipId);
  }

  @override
  Future<Map<String, dynamic>?> selectPendingRequestBetween({
    required String userA,
    required String userB,
  }) {
    return _client
        .from(_requestsTable)
        .select('id')
        .or(
          'and(sender_id.eq.$userA,receiver_id.eq.$userB),'
          'and(sender_id.eq.$userB,receiver_id.eq.$userA)',
        )
        .eq('status', 'pending')
        .maybeSingle();
  }

  @override
  Future<void> insertFriendRequest(Map<String, dynamic> values) async {
    await _client.from(_requestsTable).insert(values);
  }

  @override
  Future<List<Map<String, dynamic>>> selectPendingRequestsForReceiver(
    String userId,
  ) async {
    final rows = await _client
        .from(_requestsTable)
        .select(_requestColumns)
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectPendingRequestsForSender(
    String userId,
  ) async {
    final rows = await _client
        .from(_requestsTable)
        .select(_requestColumns)
        .eq('sender_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> selectFriendRequestById(String requestId) {
    return _client
        .from(_requestsTable)
        .select(_requestColumns)
        .eq('id', requestId)
        .maybeSingle();
  }

  @override
  Future<void> updateFriendRequestStatus(
    String requestId,
    String status,
  ) async {
    await _client
        .from(_requestsTable)
        .update({'status': status}).eq('id', requestId);
  }

  @override
  Future<int> countPendingRequestsForReceiver(String userId) async {
    final rows = await _client
        .from(_requestsTable)
        .select('id')
        .eq('receiver_id', userId)
        .eq('status', 'pending');
    return (rows as List<dynamic>).length;
  }
}
