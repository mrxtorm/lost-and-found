import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section of the Terms of Service / User Agreement.
class TermsSection {
  final String heading;
  final String body;

  const TermsSection(this.heading, this.body);
}

/// Content of the Terms of Service and User Agreement, plus the Firestore
/// record of who accepted which version.
///
/// Keep [currentVersion] equal to `requiredTermsVersion()` in
/// firestore.rules - the rules enforce it server-side.
/// Bump [currentVersion] whenever the text below changes in a way users must
/// re-accept. Every signed-in user whose latest accepted version differs
/// is asked to accept again before reaching the app (see `AccessGate`).
class TermsService {
  static const String currentVersion = '1.0';
  static const String lastUpdated = 'October 17, 2026';

  static const List<TermsSection> sections = [
    TermsSection(
      '1. Acceptance of These Terms',
      'By creating an account or using Campus Lost & Found, you agree to this '
          'Terms of Service and User Agreement. If you do not agree, you may '
          'not register or use the app.',
    ),
    TermsSection(
      '2. Purpose of the App',
      'Campus Lost & Found helps members of the campus community report lost '
          'items, report found items, and return items to their rightful '
          'owners. The app must be used only for this purpose.',
    ),
    TermsSection(
      '3. Acceptable Behavior',
      'You agree to:\n'
          '• Provide accurate and truthful information in every post, claim '
          'and message.\n'
          '• Post only items that you have genuinely lost or found.\n'
          '• Make a claim only for an item that is truly yours.\n'
          '• Treat other users respectfully and communicate honestly.\n'
          '• Keep your account credentials private and use only your own '
          'account.',
    ),
    TermsSection(
      '4. Prohibited Content and Conduct',
      'You must not:\n'
          '• Post fake, misleading or deliberately inaccurate reports, '
          'photos or descriptions.\n'
          '• Submit false claims or try to take an item that is not yours.\n'
          '• Harass, threaten, insult, discriminate against or abuse any '
          'user.\n'
          '• Post spam, advertising, scams, or unrelated content.\n'
          '• Post obscene, violent, illegal or otherwise inappropriate '
          'content or images.\n'
          '• Share another person\'s private information without their '
          'permission.\n'
          '• Impersonate another person or create accounts to evade a '
          'warning, suspension or ban.\n'
          '• Interfere with, attack or misuse the app or its data.',
    ),
    TermsSection(
      '5. Item Claims and Verification',
      'Finders may ask claimants to answer a verification question. Answers '
          'must be truthful. A finder may approve or reject a claim based on '
          'the information provided. Approving a claim completes the return '
          'and the related post, claim and conversation may be removed from '
          'the app.',
    ),
    TermsSection(
      '6. Reporting Violations',
      'If you see a post, claim or message that breaks these rules, report '
          'it using the reporting tools provided in the app, or contact the '
          'campus administrators. Include a short explanation of the problem. '
          'Reports are reviewed and handled according to the severity of the '
          'violation. Do not submit false or abusive reports; doing so is '
          'itself a violation of these Terms.',
    ),
    TermsSection(
      '7. Consequences of Violations',
      'Content that violates these Terms may be removed. Depending on the '
          'severity and frequency of the violation, a user may receive:\n'
          '• a warning;\n'
          '• a temporary suspension (for example, being unable to post for a '
          'period of time); or\n'
          '• a permanent ban from the app.\n\n'
          'Posting fake, misleading or abusive content, false claims, '
          'harassment, and repeated or serious violations may result in '
          'harsher action, up to a permanent ban, without prior warning. '
          'Serious violations may also be referred to the campus '
          'administration for further action.',
    ),
    TermsSection(
      '8. Your Information',
      'We store the information you provide (such as your name, email, '
          'posts, claims, messages and photos) to operate the app. Messages '
          'and claim details are visible only to the people involved. We '
          'record when you accepted these Terms and which version you '
          'accepted.',
    ),
    TermsSection(
      '9. Changes to These Terms',
      'These Terms may be updated. When they change, a new version number '
          'will be published and you will be asked to review and accept the '
          'updated version before continuing to use the app.',
    ),
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// One document per user per version: `<uid>_<version>`.
  DocumentReference<Map<String, dynamic>> _docFor(String uid) =>
      _firestore.collection('termsAcceptances').doc('${uid}_$currentVersion');

  String _cacheKey(String uid) => 'terms_accepted_${uid}_$currentVersion';

  /// True if [uid] has accepted [currentVersion].
  ///
  /// Firestore is the source of truth. Once confirmed, the result is cached
  /// on this device so a user who already accepted can still open the app
  /// offline (the app is offline-first). With no network and no cached
  /// confirmation the original error is rethrown.
  Future<bool> hasAcceptedCurrent(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final snap = await _docFor(uid).get();
      if (snap.exists) await prefs.setBool(_cacheKey(uid), true);
      return snap.exists;
    } catch (_) {
      if (prefs.getBool(_cacheKey(uid)) == true) return true;
      rethrow;
    }
  }

  /// Records that the signed-in user accepted [currentVersion]. The write is
  /// create-only in Firestore rules, so an existing record is never altered.
  Future<void> recordAcceptance() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final ref = _docFor(user.uid);
    if (!(await ref.get()).exists) {
      await ref.set({
        'userId': user.uid,
        'email': user.email ?? '',
        'version': currentVersion,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey(user.uid), true);
  }
}
