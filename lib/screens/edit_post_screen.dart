import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_category.dart';
import '../models/item_model.dart';
import '../providers/item_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';

/// Lets the owner change the text details of one of their posts (name,
/// category, location, date, description and - for found items - the
/// verification question). Photos and the Lost/Found type stay as posted.
class EditPostScreen extends StatefulWidget {
  final ItemModel item;

  const EditPostScreen({super.key, required this.item});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _questionController;

  late String _category;
  late DateTime _date;

  bool _isSaving = false;
  bool _saved = false;

  static final List<_Choice> _categories = [
    for (final c in ItemCategory.all) _Choice(c.name, c.icon, c.color),
  ];


  bool get _isFound => widget.item.status.toLowerCase() == 'found';

  String get _formattedDate => '${_date.month}/${_date.day}/${_date.year}';

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.title);
    _descriptionController = TextEditingController(text: item.description);
    _locationController = TextEditingController(text: item.location);
    _questionController =
        TextEditingController(text: item.verificationQuestion ?? '');
    // Old posts may use a retired name (e.g. "Wallet"); show its new one.
    _category = ItemCategory.canonical(item.category);
    _date = _parseDate(item.date) ?? DateTime.now();

    for (final c in [
      _nameController,
      _descriptionController,
      _locationController,
      _questionController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  /// Posts store their date as M/D/YYYY (see ReportItemScreen).
  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Only the fields that actually changed, so an unchanged form saves nothing.
  Map<String, dynamic> get _changes {
    final item = widget.item;
    final title = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final question = _questionController.text.trim();

    return {
      if (title != item.title) 'title': title,
      if (description != item.description) 'description': description,
      if (_category != ItemCategory.canonical(item.category))
        'category': _category,
      if (location != item.location) 'location': location,
      if (_formattedDate != item.date) 'date': _formattedDate,
      if (_isFound && question != (item.verificationQuestion ?? ''))
        'verificationQuestion': question,
    };
  }

  bool get _isDirty => _changes.isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final changes = _changes;
    if (changes.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    // Saving anyway, so move an old post onto the current category name.
    if (_category != widget.item.category) changes['category'] = _category;

    setState(() => _isSaving = true);
    try {
      await context.read<ItemProvider>().updateItem(widget.item.id, changes);
      if (!mounted) return;
      _saved = true;
      AppSnack.show(context, 'Post updated.', kind: SnackKind.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, 'Failed to update post: $e',
          kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this post will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.lost),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _saved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSaving) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Edit post'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _label('Item name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                style: _inputStyle,
                decoration: _decoration(hint: 'e.g. Black iPhone 13'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the item name.'
                    : null,
              ),
              _label('Category'),
              _dropdown(
                value: _category,
                choices: _categories,
                onChanged: (v) => setState(() => _category = v!),
              ),
              _label('Location'),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                style: _inputStyle,
                decoration: _decoration(
                  hint: 'e.g. 2nd floor library, near the printers',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.muted,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter where it happened.'
                    : null,
              ),
              _label(_isFound ? 'Date found' : 'Date lost'),
              _dateField(),
              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                style: _inputStyle,
                decoration: _decoration(hint: 'Color, brand, marks...'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Add a short description.'
                    : null,
              ),
              if (_isFound) ...[
                _label('Verification question'),
                TextFormField(
                  controller: _questionController,
                  textCapitalization: TextCapitalization.sentences,
                  style: _inputStyle,
                  decoration: _decoration(
                    hint: 'A question only the real owner could answer',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Add a question only the real owner could answer.'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Photos and the Lost/Found type can\'t be changed. '
                'Delete and re-post if those are wrong.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: _isSaving || !_isDirty ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle get _inputStyle =>
      TextStyle(fontSize: 17, color: AppColors.ink);

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.lost),
      focusedErrorBorder: border(AppColors.lost, 1.5),
    );
  }

  Widget _dropdown({
    required String value,
    required List<_Choice> choices,
    required ValueChanged<String?> onChanged,
  }) {
    // Keep older posts editable even if their value isn't in today's list.
    final options = [
      ...choices,
      if (value.isNotEmpty && !choices.any((c) => c.name == value))
        _Choice(value, Icons.label_outline_rounded, AppColors.muted),
    ];

    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: AppColors.surface,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 28,
        color: AppColors.muted,
      ),
      style: _inputStyle,
      decoration: _decoration(),
      validator: (v) => v == null ? 'Choose one.' : null,
      items: [
        for (final choice in options)
          DropdownMenuItem<String>(
            value: choice.name,
            child: Row(
              children: [
                Icon(choice.icon, size: 22, color: choice.color),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(choice.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 22, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(_formattedDate, style: _inputStyle)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 28, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Choice {
  final String name;
  final IconData icon;
  final Color color;

  const _Choice(this.name, this.icon, this.color);
}
