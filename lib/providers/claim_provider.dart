import 'package:flutter/foundation.dart';

import '../data/repositories/claim_repository.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../services/claim_service.dart';

/// Handles claim submission state so [ClaimItemScreen] doesn't need its
/// own repository instance or isSubmitting flag.
///
/// Submission is offline-first: [ClaimRepository.submitClaim] always saves
/// the claim locally first (so it can never be lost) and pushes it to
/// Firestore in the background, so this never has to surface a "you're
/// offline" error to the user.
class ClaimProvider with ChangeNotifier {
  final ClaimRepository _claimRepository;

  // Not currently wired to any screen (no "review received claims" UI
  // exists yet), kept as-is (online-only, same as before this feature)
  // so the capability isn't lost.
  final ClaimService _claimService = ClaimService();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _currentUserId;

  ClaimProvider(this._claimRepository);

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Call whenever the signed-in user changes (including sign-out).
  ///
  /// Starts (or restarts) the live Firestore listener for claims made
  /// against items [uid] owns, so the claim panel in a conversation is
  /// populated from the server - not just from the claimant's own optimistic
  /// local write. Without this, `ClaimRepository.startRemoteSync` is never
  /// called, so a finder's cached claim (deleted on logout by
  /// `clearUserScopedCacheOnLogout`) never comes back after signing in again.
  void setCurrentUserId(String? uid) {
    if (_currentUserId == uid) return;
    if (_currentUserId != null) {
      _claimRepository.stopRemoteSync(_currentUserId!);
    }
    _currentUserId = uid;
    if (uid != null) {
      _claimRepository.startRemoteSync(uid);
    }
  }

  /// Submits a claim for [item]. Returns true on success; on failure,
  /// [errorMessage] is populated and false is returned.
  Future<bool> submitClaim({
    required ItemModel item,
    required String answer,
    required String additionalDetails,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _claimRepository.submitClaim(
        item: item,
        answer: answer,
        additionalDetails: additionalDetails,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Stream<List<ClaimModel>> streamClaimsForOwner(String ownerId) {
    return _claimRepository.watchClaimsForOwner(ownerId);
  }

  Future<void> updateClaimStatus(String claimId, String status) {
    return _claimService.updateClaimStatus(claimId, status);
  }
}
