import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Loads and validates a conversation before the messages listener is started.
///
/// The loader intentionally performs a one-time Firestore read first. This
/// avoids attaching a messages listener to a conversation that has not been
/// hydrated yet and gives the UI a deterministic loading/permission state.
class ConversationLoader {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ConversationLoader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<ConversationLoadResult> load(String conversationId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const ConversationLoadResult.unauthenticated();
    }

    if (conversationId.trim().isEmpty) {
      return const ConversationLoadResult.notFound();
    }

    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get(const GetOptions(source: Source.server));

      if (!snapshot.exists || snapshot.data() == null) {
        return const ConversationLoadResult.notFound();
      }

      final data = snapshot.data()!;
      final rawParticipants = data['participantIds'];

      final participantIds = rawParticipants is List
          ? rawParticipants.map((e) => e.toString()).toList()
          : <String>[];

      if (!participantIds.contains(user.uid)) {
        return const ConversationLoadResult.forbidden();
      }

      return ConversationLoadResult.success(
        conversationId: snapshot.id,
        data: data,
        participantIds: participantIds,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return ConversationLoadResult.error(
          'You do not have permission to access this conversation.',
          code: e.code,
        );
      }

      if (e.code == 'not-found') {
        return const ConversationLoadResult.notFound();
      }

      return ConversationLoadResult.error(
        e.message ?? 'Failed to load conversation.',
        code: e.code,
      );
    } catch (e) {
      return ConversationLoadResult.error(
        'Failed to load conversation: $e',
      );
    }
  }
}

class ConversationLoadResult {
  final ConversationLoadStatus status;
  final String? conversationId;
  final Map<String, dynamic>? data;
  final List<String> participantIds;
  final String? message;
  final String? code;

  const ConversationLoadResult._({
    required this.status,
    this.conversationId,
    this.data,
    this.participantIds = const [],
    this.message,
    this.code,
  });

  const ConversationLoadResult.success({
    required String conversationId,
    required Map<String, dynamic> data,
    required List<String> participantIds,
  }) : this._(
          status: ConversationLoadStatus.success,
          conversationId: conversationId,
          data: data,
          participantIds: participantIds,
        );

  const ConversationLoadResult.notFound()
      : this._(status: ConversationLoadStatus.notFound);

  const ConversationLoadResult.forbidden()
      : this._(status: ConversationLoadStatus.forbidden);

  const ConversationLoadResult.unauthenticated()
      : this._(status: ConversationLoadStatus.unauthenticated);

  const ConversationLoadResult.error(String message, {String? code})
      : this._(
          status: ConversationLoadStatus.error,
          message: message,
          code: code,
        );

  bool get isSuccess => status == ConversationLoadStatus.success;
}

enum ConversationLoadStatus {
  success,
  notFound,
  forbidden,
  unauthenticated,
  error,
}
