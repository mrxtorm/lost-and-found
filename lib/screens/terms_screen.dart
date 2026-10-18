import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../services/terms_service.dart';

/// Shows the Terms of Service and User Agreement.
///
/// With [requireAcceptance] false it is a plain reader (opened from the
/// register screen). With it true, the user must accept to continue: the
/// screen offers Accept / Decline and pops with `true` or `false`.
class TermsScreen extends StatelessWidget {
  final bool requireAcceptance;

  const TermsScreen({super.key, this.requireAcceptance = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !requireAcceptance,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms of Service'),
          centerTitle: true,
          automaticallyImplyLeading: !requireAcceptance,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Terms of Service and User Agreement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${TermsService.currentVersion} · '
                    'Last updated ${TermsService.lastUpdated}',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  for (final section in TermsService.sections) ...[
                    Text(
                      section.heading,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      section.body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            if (requireAcceptance)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('I Accept'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
