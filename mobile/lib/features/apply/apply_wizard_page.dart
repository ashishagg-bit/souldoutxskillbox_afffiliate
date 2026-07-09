import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/options.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/step_progress.dart';

/// Direct port of `features/apply/apply-wizard.component.ts`. A 4-step
/// wizard: Connect Instagram -> City/niche -> Upload insights -> Review.
class ApplyWizardPage extends StatefulWidget {
  const ApplyWizardPage({super.key});

  @override
  State<ApplyWizardPage> createState() => _ApplyWizardPageState();
}

class _ApplyWizardPageState extends State<ApplyWizardPage> {
  int _step = 1;
  static const _totalSteps = 4;

  String? _uploadedFileName;
  late final TextEditingController _handleController;
  late final TextEditingController _followersController;
  late final TextEditingController _engagementController;
  late final TextEditingController _audienceController;

  @override
  void initState() {
    super.initState();
    final app = context.read<ApplicationStateProvider>().application;
    _handleController = TextEditingController(text: app.socials.instagramHandle);
    _followersController = TextEditingController(text: app.insights.followers > 0 ? '${app.insights.followers}' : '');
    _engagementController =
        TextEditingController(text: app.insights.engagementRate > 0 ? '${app.insights.engagementRate}' : '');
    _audienceController =
        TextEditingController(text: app.insights.audienceIndiaPercent > 0 ? '${app.insights.audienceIndiaPercent}' : '');
  }

  @override
  void dispose() {
    _handleController.dispose();
    _followersController.dispose();
    _engagementController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step == 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  void _goNext() {
    if (_step < _totalSteps) setState(() => _step += 1);
  }

  void _submit() {
    context.read<ApplicationStateProvider>().submitApplication();
    Navigator.of(context).pushReplacementNamed('/gigs/status');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final app = appState.application;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(onPressed: _goBack, icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink)),
                  const Expanded(
                    child: Text('APPLY',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            StepProgress(current: _step, total: _totalSteps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: switch (_step) {
                  1 => _buildStep1(context, appState, app),
                  2 => _buildStep2(context, appState, app),
                  3 => _buildStep3(context, appState, app),
                  _ => _buildStep4(context, app),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context, ApplicationStateProvider appState, AffiliateApplication app) {
    final canContinue = app.socials.instagramHandle.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Connect Instagram', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text('We verify your account to calculate your score. Your handle is never shared.',
            style: TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.4)),
        const SizedBox(height: 24),
        const Text('Instagram handle', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.panel),
                child: const Text('@', style: TextStyle(fontSize: 15, color: AppColors.faint)),
              ),
              Expanded(
                child: TextField(
                  controller: _handleController,
                  decoration: const InputDecoration(
                      hintText: 'yourhandle', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  onChanged: (v) {
                    appState.setInstagramHandle(v.replaceFirst(RegExp(r'^@'), ''));
                    if (v.trim().isNotEmpty && !app.socials.platforms.contains(SocialPlatform.instagram)) {
                      appState.togglePlatform(SocialPlatform.instagram);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Other platforms (select all that apply)', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        Column(
          children: [
            for (var i = 0; i < platformOptions.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _platformButton(appState, app, platformOptions[i])),
                  const SizedBox(width: 12),
                  if (i + 1 < platformOptions.length)
                    Expanded(child: _platformButton(appState, app, platformOptions[i + 1]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        _continueButton(enabled: canContinue, onPressed: _goNext),
      ],
    );
  }

  Widget _platformButton(ApplicationStateProvider appState, AffiliateApplication app, SocialPlatform p) {
    final selected = app.socials.platforms.contains(p);
    return OutlinedButton.icon(
      onPressed: () => appState.togglePlatform(p),
      icon: Icon(_platformIcon(p), size: 18, color: AppColors.ink),
      label: Text(p.label, style: const TextStyle(color: AppColors.ink)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: selected ? Colors.black : AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  IconData _platformIcon(SocialPlatform p) => switch (p) {
        SocialPlatform.instagram => Icons.camera_alt_outlined,
        SocialPlatform.youtube => Icons.play_circle_outline,
        SocialPlatform.snapchat => Icons.emoji_emotions_outlined,
        SocialPlatform.twitter => Icons.close,
      };

  Widget _buildStep2(BuildContext context, ApplicationStateProvider appState, AffiliateApplication app) {
    final canContinue = app.locationNiche.city != null && app.locationNiche.niche != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your city and niche', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text('We match you to events and gigs in your city.', style: TextStyle(fontSize: 14.5, color: AppColors.muted)),
        const SizedBox(height: 24),
        const Text('City', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cityOptions
              .map((c) => _Pill(label: c.label, selected: app.locationNiche.city == c, onTap: () => appState.setCity(c)))
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('Content niche', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nicheOptions
              .map((n) => _Pill(label: n.label, selected: app.locationNiche.niche == n, onTap: () => appState.setNiche(n)))
              .toList(),
        ),
        const SizedBox(height: 32),
        _continueButton(enabled: canContinue, onPressed: _goNext),
      ],
    );
  }

  Widget _buildStep3(BuildContext context, ApplicationStateProvider appState, AffiliateApplication app) {
    final canContinue = app.insights.followers > 0 && app.insights.engagementRate > 0 && app.insights.contentFormat != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload Instagram insights', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text(
          'Screenshot your Instagram insights (Followers, Engagement, Audience location) so we can verify your numbers.',
          style: TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            setState(() => _uploadedFileName = 'instagram-insights.png');
            appState.setInsights(screenshotFileName: 'instagram-insights.png');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line, width: 1.5, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.file_upload_outlined, size: 26, color: AppColors.gray400),
                const SizedBox(height: 8),
                Text(_uploadedFileName ?? 'Tap to upload screenshot', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Followers', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 8),
        _numberField(_followersController, 'e.g. 68000', (v) => appState.setInsights(followers: int.tryParse(v) ?? 0)),
        const SizedBox(height: 18),
        const Text('Engagement rate (%)', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 8),
        _numberField(_engagementController, 'e.g. 3.2', (v) => appState.setInsights(engagementRate: double.tryParse(v) ?? 0)),
        const SizedBox(height: 18),
        const Text('Primary content format', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: contentFormatOptions
              .map((f) => _Pill(
                    label: f.label,
                    selected: app.insights.contentFormat == f,
                    onTap: () => appState.setContentFormat(f),
                  ))
              .toList(),
        ),
        const SizedBox(height: 18),
        const Text('Audience from India (%)', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 8),
        _numberField(_audienceController, 'e.g. 78', (v) => appState.setInsights(audienceIndiaPercent: int.tryParse(v) ?? 0)),
        const SizedBox(height: 32),
        _continueButton(enabled: canContinue, onPressed: _goNext),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String hint, ValueChanged<String> onChanged) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      ),
    );
  }

  Widget _buildStep4(BuildContext context, AffiliateApplication app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ready to submit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text('A Skillbox reviewer will verify your profile within 48 hours.',
            style: TextStyle(fontSize: 14.5, color: AppColors.muted)),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _summaryRow('Instagram', '@${app.socials.instagramHandle}'),
              const Divider(height: 1, color: AppColors.line),
              _summaryRow('Platforms', app.socials.platforms.map((p) => p.label).join(', ')),
              const Divider(height: 1, color: AppColors.line),
              _summaryRow('City', app.locationNiche.city?.label ?? ''),
              const Divider(height: 1, color: AppColors.line),
              _summaryRow('Niche', app.locationNiche.niche?.label ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Submit application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _continueButton({required bool enabled, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.black : Colors.white,
        foregroundColor: selected ? Colors.white : AppColors.ink,
        side: BorderSide(color: selected ? Colors.black : AppColors.line),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
