import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/scoring_weights_provider.dart';
import '../../core/providers/tier_settings_provider.dart';
import '../../core/scoring/scoring.dart';
import '../../shared/app_colors.dart';

/// Direct port of `features/application-status/application-status.component.ts`.
class ApplicationStatusPage extends StatelessWidget {
  const ApplicationStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final tierBands = context.watch<TierSettingsProvider>().tierBands;
    final weights = context.watch<ScoringWeightsProvider>().weights;
    final app = appState.application;
    final status = app.status;
    final score = computeScore(app.insights, app.performance, tierBands: tierBands, weights: weights);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: status == ApplicationStatus.rejected ? AppColors.red50 : AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  status == ApplicationStatus.rejected ? Icons.close : Icons.check_circle_outline,
                  size: 28,
                  color: status == ApplicationStatus.rejected ? AppColors.red700 : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              switch (status) {
                ApplicationStatus.approved => "You're approved!",
                ApplicationStatus.rejected => 'Application not approved',
                _ => 'Application sent',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              switch (status) {
                ApplicationStatus.approved => 'Your profile is verified and the gig marketplace is unlocked.',
                ApplicationStatus.rejected =>
                  "Your profile didn't meet our current audience quality bar. You're welcome to re-apply once your Instagram engagement grows.",
                _ => "We're reviewing your profile. You'll get a WhatsApp message within 48 hours.",
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.4),
            ),
            if (status != ApplicationStatus.rejected) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _StatusStep(
                      title: 'Application submitted',
                      subtitle: 'Done',
                      state: _StepState.done,
                    ),
                    const Divider(height: 1, color: AppColors.line),
                    _StatusStep(
                      title: 'Skillbox review',
                      subtitle: status == ApplicationStatus.approved
                          ? 'A reviewer checked your audience quality and engagement'
                          : 'Within 48 hours — we check your audience quality and engagement',
                      state: status == ApplicationStatus.approved ? _StepState.done : _StepState.active,
                    ),
                    const Divider(height: 1, color: AppColors.line),
                    _StatusStep(
                      title: 'Score assigned',
                      subtitle: status == ApplicationStatus.approved
                          ? "You're ${score.tier.label} tier, score ${score.total}/100"
                          : 'Your 0–100 score determines which gigs you can access',
                      state: status == ApplicationStatus.approved ? _StepState.done : _StepState.pending,
                    ),
                    const Divider(height: 1, color: AppColors.line),
                    _StatusStep(
                      title: 'Gig marketplace unlocked',
                      subtitle: 'Apply to gigs matched to your score tier',
                      state: status == ApplicationStatus.approved ? _StepState.done : _StepState.pending,
                    ),
                  ],
                ),
              ),
            ],
            if (status == ApplicationStatus.underReview) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('While you wait', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    SizedBox(height: 6),
                    Text(
                      'Make sure your Instagram is public and your recent posts reflect your content style. '
                      'Reviewers look at your last 30 posts.',
                      style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (status == ApplicationStatus.approved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/gigs/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Go to marketplace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              )
            else if (status != ApplicationStatus.rejected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/gigs/dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Preview the marketplace (pending approval)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _StatusStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final _StepState state;

  const _StatusStep({required this.title, required this.subtitle, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StepState.done;
    final isActive = state == _StepState.active;
    return Opacity(
      opacity: state == _StepState.pending ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone ? Colors.black : (isActive ? AppColors.accentSoft : AppColors.panel),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : (isActive ? Icons.schedule : Icons.circle_outlined),
                size: 16,
                color: isDone ? Colors.white : (isActive ? AppColors.accent : AppColors.faint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.faint, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
