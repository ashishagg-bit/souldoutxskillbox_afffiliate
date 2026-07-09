import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/options.dart';
import '../../core/models/types.dart';
import '../../core/providers/gigs_provider.dart';
import '../../shared/app_colors.dart';

/// Direct port of `features/admin/admin-shows.component.ts`. Full CRUD on
/// the marketplace's gigs, including the per-ticket commission model.
class AdminShowsTab extends StatefulWidget {
  const AdminShowsTab({super.key});

  @override
  State<AdminShowsTab> createState() => _AdminShowsTabState();
}

class _AdminShowsTabState extends State<AdminShowsTab> {
  bool _formOpen = false;
  String? _editingId;

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _spotsController = TextEditingController();
  final _deliverableController = TextEditingController();
  final _payoutMinController = TextEditingController();
  final _payoutMaxController = TextEditingController();
  final _minScoreController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _commissionRateController = TextEditingController();
  GigType _type = GigType.storyCoverage;
  Tier _minTier = Tier.bronze;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _spotsController.dispose();
    _deliverableController.dispose();
    _payoutMinController.dispose();
    _payoutMaxController.dispose();
    _minScoreController.dispose();
    _ticketPriceController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  void _startCreate() {
    _editingId = null;
    _titleController.clear();
    _locationController.clear();
    _dateController.clear();
    _spotsController.clear();
    _deliverableController.clear();
    _payoutMinController.clear();
    _payoutMaxController.clear();
    _minScoreController.text = '0';
    _ticketPriceController.clear();
    _commissionRateController.clear();
    _type = GigType.storyCoverage;
    _minTier = Tier.bronze;
    setState(() => _formOpen = true);
  }

  void _startEdit(Gig gig) {
    _editingId = gig.id;
    _titleController.text = gig.title;
    _locationController.text = gig.location ?? '';
    _dateController.text = gig.date ?? '';
    _spotsController.text = gig.spotsLeft?.toString() ?? '';
    _deliverableController.text = gig.deliverable ?? '';
    _payoutMinController.text = gig.payoutMin.toString();
    _payoutMaxController.text = gig.payoutMax.toString();
    _minScoreController.text = gig.minScore.toString();
    _ticketPriceController.text = gig.ticketPrice?.toString() ?? '';
    _commissionRateController.text = gig.commissionRate?.toString() ?? '';
    _type = gig.type;
    _minTier = gig.minTier;
    setState(() => _formOpen = true);
  }

  void _cancel() => setState(() => _formOpen = false);

  void _save() {
    final title = _titleController.text.trim();
    final payoutMin = int.tryParse(_payoutMinController.text) ?? 0;
    final payoutMax = int.tryParse(_payoutMaxController.text) ?? 0;
    if (title.isEmpty || payoutMax < payoutMin) return;

    final gigsProvider = context.read<GigsProvider>();
    final draft = Gig(
      id: _editingId ?? '',
      type: _type,
      minTier: _minTier,
      minScore: int.tryParse(_minScoreController.text) ?? 0,
      title: title,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      date: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      spotsLeft: int.tryParse(_spotsController.text),
      deliverable: _deliverableController.text.trim().isEmpty ? null : _deliverableController.text.trim(),
      payoutMin: payoutMin,
      payoutMax: payoutMax,
      ticketPrice: int.tryParse(_ticketPriceController.text),
      commissionRate: double.tryParse(_commissionRateController.text),
    );

    if (_editingId != null) {
      gigsProvider.updateGig(_editingId!, (_) => draft.copyWith()._withId(_editingId!));
    } else {
      gigsProvider.addGig(draft);
    }
    _cancel();
  }

  Future<void> _delete(Gig gig) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove show?'),
        content: Text('Remove "${gig.title}" from the marketplace?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<GigsProvider>().deleteGig(gig.id);
    }
  }

  String _fmtCurrency(num n) => '₹${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  String _formatPayout(Gig g) => g.payoutMin == g.payoutMax ? _fmtCurrency(g.payoutMin) : '${_fmtCurrency(g.payoutMin)}–${_fmtCurrency(g.payoutMax)}';

  @override
  Widget build(BuildContext context) {
    final gigsProvider = context.watch<GigsProvider>();
    final gigs = gigsProvider.gigs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Shows in the marketplace (${gigs.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
            ElevatedButton(
              onPressed: _startCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('+ Add show', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (_formOpen) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_editingId != null ? 'Edit show' : 'New show',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 16),
                _labeledField('Title', _titleController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledDropdown<GigType>(
                        'Type',
                        _type,
                        gigTypeOptions,
                        (t) => t.label,
                        (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _labeledDropdown<Tier>(
                        'Minimum tier',
                        _minTier,
                        tierOptions,
                        (t) => t.label,
                        (v) => setState(() => _minTier = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _labeledField('Minimum score', _minScoreController, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _labeledField('Location', _locationController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _labeledField('Date (free text)', _dateController, hint: 'e.g. 22 Feb or 14-16 Mar')),
                    const SizedBox(width: 12),
                    Expanded(child: _labeledField('Spots left (optional)', _spotsController, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _labeledField('Deliverable (optional)', _deliverableController, hint: 'e.g. 3 Reels · 30 sec each'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _labeledField('Payout min (₹)', _payoutMinController, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _labeledField('Payout max (₹)', _payoutMaxController, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Per-ticket commission (optional)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      const Text(
                        'Set both to make this a link-promotable show (Story coverage / Attendance). Leave blank for a flat-fee content gig.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _labeledField('Ticket price (₹)', _ticketPriceController, isNumber: true, filled: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _labeledField('Commission rate (%)', _commissionRateController, isNumber: true, filled: true)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_editingId != null ? 'Save changes' : 'Create show', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...gigs.map((gig) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gig.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(
                          '${gig.type.label} · requires ${gig.minTier.label}+ (score ${gig.minScore}) · ${_formatPayout(gig)}'
                          '${gig.ticketPrice != null && gig.commissionRate != null ? ' · ${gig.commissionRate}% commission on ₹${gig.ticketPrice} tickets' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _startEdit(gig),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _delete(gig),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red700,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Delete', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _labeledField(String label, TextEditingController controller, {String? hint, bool isNumber = false, bool filled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: filled,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
          ),
        ),
      ],
    );
  }

  Widget _labeledDropdown<T>(String label, T value, List<T> options, String Function(T) labelFn, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(labelFn(o), style: const TextStyle(fontSize: 13.5)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
          ),
        ),
      ],
    );
  }
}

extension _WithIdExt on Gig {
  Gig _withId(String newId) => Gig(
        id: newId,
        type: type,
        minTier: minTier,
        minScore: minScore,
        title: title,
        location: location,
        date: date,
        spotsLeft: spotsLeft,
        deliverable: deliverable,
        payoutMin: payoutMin,
        payoutMax: payoutMax,
        ticketPrice: ticketPrice,
        commissionRate: commissionRate,
      );
}
