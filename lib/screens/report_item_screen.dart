import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/item_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'draft_matches_screen.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  String selectedType = 'Lost';

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController verificationQuestionController =
  TextEditingController();

  String? selectedCategory;
  String? selectedLocation;
  late DateTime selectedDate;

  static const int _maxPhotos = 5;
  final List<File> selectedImages = [];

  final ImagePicker imagePicker = ImagePicker();
  bool isSubmitting = false;
  bool _showErrors = false;
  bool _posted = false;

  // Used to scroll to the first section that needs attention.
  final GlobalKey _photoKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();
  final GlobalKey _verificationKey = GlobalKey();

  static const List<_Choice> _categories = [
    _Choice('Electronics', Icons.phone_android_rounded, Color(0xFF2F5BEA)),
    _Choice('Wallet', Icons.account_balance_wallet_rounded, Color(0xFFE08A00)),
    _Choice('ID', Icons.badge_rounded, Color(0xFF1F9D68)),
    _Choice('Keys', Icons.key_rounded, Color(0xFFE5484D)),
    _Choice('Books', Icons.menu_book_rounded, Color(0xFF7C3AED)),
    _Choice('Others', Icons.category_rounded, Color(0xFF0891B2)),
  ];

  static const List<_Choice> _locations = [
    _Choice('Library', Icons.local_library_rounded, AppColors.muted),
    _Choice('Classroom', Icons.school_rounded, AppColors.muted),
    _Choice('Laboratory', Icons.science_rounded, AppColors.muted),
    _Choice('Cafeteria', Icons.restaurant_rounded, AppColors.muted),
    _Choice('Gymnasium', Icons.fitness_center_rounded, AppColors.muted),
    _Choice('Main Building', Icons.apartment_rounded, AppColors.muted),
    _Choice('Other', Icons.more_horiz_rounded, AppColors.muted),
  ];

  static const List<String> _questionIdeas = [
    'What is the lock screen wallpaper?',
    'What is inside it?',
    'What color is the case?',
    'What sticker or mark is on it?',
  ];

  bool get _isFound => selectedType == 'Found';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    verificationQuestionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // PROGRESS + VALIDATION
  // ---------------------------------------------------------------------

  bool get _hasPhoto => selectedImages.isNotEmpty;
  bool get _hasName => itemNameController.text.trim().isNotEmpty;
  bool get _hasDescription => descriptionController.text.trim().isNotEmpty;
  bool get _hasQuestion =>
      verificationQuestionController.text.trim().isNotEmpty;

  // A photo is mandatory for found items only; lost-item reports may be
  // posted without one.
  int get _totalRequired => _isFound ? 6 : 4;

  int get _completed => [
    if (_isFound) _hasPhoto,
    _hasName,
    selectedCategory != null,
    selectedLocation != null,
    _hasDescription,
    if (_isFound) _hasQuestion,
  ].where((done) => done).length;

  bool get _isDirty =>
      _hasPhoto ||
          selectedCategory != null ||
          selectedLocation != null ||
          _hasName ||
          _hasDescription ||
          _hasQuestion;

  String? get _photoError =>
      _showErrors && _isFound && !_hasPhoto
          ? 'Add at least one photo so the owner can recognize it.'
          : null;

  String? get _nameError =>
      _showErrors && !_hasName ? 'Enter the item name.' : null;

  String? get _categoryError =>
      _showErrors && selectedCategory == null ? 'Choose a category.' : null;

  String? get _locationError =>
      _showErrors && selectedLocation == null ? 'Choose a location.' : null;

  String? get _descriptionError =>
      _showErrors && !_hasDescription ? 'Add a short description.' : null;

  String? get _verificationError => _showErrors && _isFound && !_hasQuestion
      ? 'Add a question only the real owner could answer.'
      : null;

  int get _errorCount => [
    _photoError,
    _nameError,
    _categoryError,
    _locationError,
    _descriptionError,
    _verificationError,
  ].where((error) => error != null).length;

  GlobalKey? get _firstInvalidKey {
    if (_photoError != null) return _photoKey;
    if (_nameError != null) return _nameKey;
    if (_categoryError != null) return _categoryKey;
    if (_locationError != null) return _locationKey;
    if (_descriptionError != null) return _descriptionKey;
    if (_verificationError != null) return _verificationKey;
    return null;
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.02,
    );
  }

  // ---------------------------------------------------------------------
  // DATE
  // ---------------------------------------------------------------------

  String get formattedDate =>
      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_sameDay(selectedDate, today)) return 'Today, $formattedDate';
    if (_sameDay(selectedDate, yesterday)) return 'Yesterday, $formattedDate';
    return formattedDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  // ---------------------------------------------------------------------
  // PHOTO
  // ---------------------------------------------------------------------

  Future<void> _pickPhoto(ImageSource source) async {
    final remaining = _maxPhotos - selectedImages.length;
    if (remaining <= 0) {
      showMessage('You can add up to $_maxPhotos photos.');
      return;
    }

    try {
      final List<XFile> picked;
      // pickMultiImage requires a limit of at least 2, so a single free slot
      // uses the regular single-image gallery picker.
      if (source == ImageSource.camera || remaining == 1) {
        final image = await imagePicker.pickImage(
          source: source == ImageSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1600,
        );
        picked = image == null ? const [] : [image];
      } else {
        picked = await imagePicker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1600,
          limit: remaining,
        );
      }

      if (picked.isEmpty || !mounted) return;

      final files = picked.take(remaining).map((x) => File(x.path)).toList();
      setState(() => selectedImages.addAll(files));

      if (picked.length > remaining) {
        showMessage('Only $_maxPhotos photos are allowed per post.');
      }
    } catch (_) {
      if (!mounted) return;
      showMessage(
        source == ImageSource.camera
            ? "Couldn't open the camera."
            : "Couldn't open your gallery.",
      );
    }
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.photo_camera_outlined, size: 28),
              title: const Text('Take a photo', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.photo_library_outlined, size: 28),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) await _pickPhoto(source);
  }

  void removePhoto(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  // ---------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------

  Future<void> submitReport() async {
    setState(() => _showErrors = true);

    final invalid = _firstInvalidKey;
    if (invalid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(invalid));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1) Check for possible matches BEFORE anything is posted.
      final matches = await context.read<ItemProvider>().findMatchesForDraft(
        title: itemNameController.text.trim(),
        category: selectedCategory!,
        status: selectedType,
      );

      if (!mounted) return;

      if (matches.isNotEmpty) {
        final shouldContinue = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => DraftMatchesScreen(
              matches: matches,
              reportType: selectedType,
            ),
          ),
        );

        if (!mounted) return;

        // User went back to edit. Nothing has been saved yet.
        if (shouldContinue != true) return;
      }

      // 2) No matches, or the user chose to continue: submit the report.
      await context.read<ItemProvider>().reportItem(
        title: itemNameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory!,
        location: selectedLocation!,
        date: formattedDate,
        status: selectedType,
        imageFiles: List<File>.of(selectedImages),
        verificationQuestion:
        _isFound ? verificationQuestionController.text.trim() : null,
      );

      if (!mounted) return;

      _posted = true;
      showMessage('Post submitted.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showMessage('Failed to submit post: $e');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void showMessage(String message) {
    AppSnack.show(context, message, kind: SnackKind.info);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this post?'),
        content: const Text(
          'What you entered will be lost.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.lost),
            child: const Text('Discard', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    return discard == true;
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _posted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || isSubmitting) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('New post'),
        ),
        body: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 10, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TYPE
                    _FormSection(
                      number: 1,
                      label: 'What are you reporting?',
                      done: true,
                      child: _buildTypeOptions(),
                    ),

                    // 2. PHOTO
                    _FormSection(
                      key: _photoKey,
                      number: 2,
                      label: _isFound ? 'Photos' : 'Photos (optional)',
                      helper: _isFound
                          ? 'A clear photo is required so the owner can '
                              'recognize it. Add up to $_maxPhotos.'
                          : 'No photo of it? You can still post. Photos help '
                              'people recognize your item (up to $_maxPhotos).',
                      done: _hasPhoto,
                      error: _photoError,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhoto(),
                          if (_isFound && selectedCategory == 'ID')
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: AppColors.warn,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cover ID numbers and other personal '
                                          'details in the photo.',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.35,
                                        color: AppColors.warn,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3. ITEM NAME
                    _FormSection(
                      key: _nameKey,
                      number: 3,
                      label: 'Item name',
                      done: _hasName,
                      error: _nameError,
                      child: TextField(
                        controller: itemNameController,
                        maxLength: 60,
                        style: _inputStyle,
                        scrollPadding: const EdgeInsets.only(bottom: 160),
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoration(
                          hint: 'e.g. Black leather wallet',
                          hasError: _nameError != null,
                        ),
                      ),
                    ),

                    // 4. CATEGORY
                    _FormSection(
                      key: _categoryKey,
                      number: 4,
                      label: 'Category',
                      done: selectedCategory != null,
                      error: _categoryError,
                      child: _buildDropdown(
                        value: selectedCategory,
                        hint: 'Select a category',
                        hintIcon: Icons.category_outlined,
                        choices: _categories,
                        hasError: _categoryError != null,
                        onChanged: (value) =>
                            setState(() => selectedCategory = value),
                      ),
                    ),

                    // 5. LOCATION
                    _FormSection(
                      key: _locationKey,
                      number: 5,
                      label: _isFound
                          ? 'Where did you find it?'
                          : 'Where did you lose it?',
                      done: selectedLocation != null,
                      error: _locationError,
                      child: _buildDropdown(
                        value: selectedLocation,
                        hint: 'Select a location',
                        hintIcon: Icons.location_on_outlined,
                        choices: _locations,
                        hasError: _locationError != null,
                        onChanged: (value) =>
                            setState(() => selectedLocation = value),
                      ),
                    ),

                    // 6. DATE
                    _FormSection(
                      number: 6,
                      label: _isFound
                          ? 'When did you find it?'
                          : 'When did you lose it?',
                      done: true,
                      child: _buildDateField(),
                    ),

                    // 7. DESCRIPTION
                    _FormSection(
                      key: _descriptionKey,
                      number: 7,
                      label: 'Description',
                      helper: _isFound
                          ? 'Describe its color, brand and condition. Keep '
                          'back one detail only the owner would know.'
                          : 'Add color, brand, marks, or anything that was '
                          'inside.',
                      done: _hasDescription,
                      error: _descriptionError,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: descriptionController,
                            minLines: 4,
                            maxLines: 8,
                            maxLength: 500,
                            style: _inputStyle,
                            scrollPadding: const EdgeInsets.only(bottom: 160),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                            decoration: _decoration(
                              hint: 'Write a short description',
                              hasError: _descriptionError != null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${descriptionController.text.length}/500',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 8. VERIFICATION QUESTION (found items only)
                    if (_isFound)
                      _FormSection(
                        key: _verificationKey,
                        number: 8,
                        label: 'Verification question',
                        helper: 'Only the real owner should be able to answer '
                            "this. You'll review their answer before "
                            'returning the item.',
                        done: _hasQuestion,
                        error: _verificationError,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: verificationQuestionController,
                              minLines: 2,
                              maxLines: 4,
                              maxLength: 140,
                              style: _inputStyle,
                              scrollPadding: const EdgeInsets.only(bottom: 160),
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) => setState(() {}),
                              decoration: _decoration(
                                hint: 'e.g. What is the lock screen wallpaper?',
                                hasError: _verificationError != null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Need an idea? Tap one:',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final idea in _questionIdeas)
                                  _SuggestionChip(
                                    label: idea,
                                    onTap: () {
                                      verificationQuestionController.value =
                                          TextEditingValue(
                                            text: idea,
                                            selection: TextSelection.collapsed(
                                              offset: idea.length,
                                            ),
                                          );
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // POST BUTTON
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : submitReport,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                ),
                icon: isSubmitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded, size: 22),
                label: Text(
                  isSubmitting
                      ? 'Posting...'
                      : (_isFound ? 'Post found item' : 'Post lost item'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _buildProgressHeader() {
    final progress = _completed / _totalRequired;
    final allDone = _completed == _totalRequired;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_completed of $_totalRequired completed',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (allDone)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.found,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.track,
                color: allDone ? AppColors.found : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_showErrors && _errorCount > 0)
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: AppColors.lost,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorCount == 1
                        ? 'Please fix 1 item marked in red.'
                        : 'Please fix $_errorCount items marked in red.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lost,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              _isFound
                  ? 'All fields are required.'
                  : 'Photos are optional. All other fields are required.',
              style: const TextStyle(fontSize: 15, color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeOptions() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TypeOption(
              title: 'I lost something',
              subtitle: 'Others can help you find it',
              icon: Icons.search_rounded,
              color: AppColors.lost,
              selected: !_isFound,
              onTap: () => setState(() => selectedType = 'Lost'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TypeOption(
              title: 'I found something',
              subtitle: 'Help return it to its owner',
              icon: Icons.volunteer_activism_rounded,
              color: AppColors.found,
              selected: _isFound,
              onTap: () => setState(() => selectedType = 'Found'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData hintIcon,
    required List<_Choice> choices,
    required bool hasError,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      itemHeight: 56,
      menuMaxHeight: 380,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 32,
        color: AppColors.muted,
      ),
      style: _inputStyle,
      decoration: _decoration(hasError: hasError).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: Row(
        children: [
          Icon(hintIcon, size: 24, color: AppColors.muted),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, color: AppColors.muted),
            ),
          ),
        ],
      ),
      items: [
        for (final choice in choices)
          DropdownMenuItem<String>(
            value: choice.name,
            child: Row(
              children: [
                Icon(choice.icon, size: 24, color: choice.color),
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

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 24,
              color: AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dateLabel,
                style: _inputStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (selectedImages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _photoError != null ? AppColors.lost : AppColors.line,
            width: _photoError != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isFound ? 'Add photos' : 'Add photos (optional)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 22),
                    label: const Text(
                      'Camera',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 22),
                    label: const Text(
                      'Gallery',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final canAddMore = selectedImages.length < _maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length + (canAddMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == selectedImages.length) {
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _chooseSource,
                  child: Container(
                    width: 112,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add more',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final image = selectedImages[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: () => FullScreenImageViewer.show(
                          context,
                          image: FileImage(image),
                          heroTag: 'draft_photo_$i',
                          caption: itemNameController.text.trim(),
                        ),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                          cacheWidth: 500,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: SizedBox.square(
                          dimension: 36,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => removePhoto(i),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            i == 0 ? 'Cover' : '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedImages.length}/$_maxPhotos photos',
          style: const TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

// =========================================================================
// SHARED BITS
// =========================================================================

const TextStyle _inputStyle = TextStyle(
  fontSize: 18,
  color: AppColors.ink,
  fontWeight: FontWeight.w500,
);

InputDecoration _decoration({String? hint, bool hasError = false}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  final base = hasError ? AppColors.lost : AppColors.line;

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 18, color: AppColors.muted),
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(base, hasError ? 1.5 : 1),
    enabledBorder: border(base, hasError ? 1.5 : 1),
    focusedBorder: border(hasError ? AppColors.lost : AppColors.primary, 2),
  );
}

class _Choice {
  final String name;
  final IconData icon;
  final Color color;

  const _Choice(this.name, this.icon, this.color);
}

/// One numbered, clearly separated block of the form. The badge turns into
/// a green check once the block is filled in.
class _FormSection extends StatelessWidget {
  final int number;
  final String label;
  final String? helper;
  final String? error;
  final bool done;
  final Widget child;

  const _FormSection({
    super.key,
    required this.number,
    required this.label,
    required this.child,
    this.helper,
    this.error,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBadge(number: number, done: done),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                helper!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ),
          const SizedBox(height: 14),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.lost,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        color: AppColors.lost,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int number;
  final bool done;

  const _StepBadge({required this.number, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.found : AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
          : Text(
        '$number',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: selected ? 0.18 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle_rounded, color: color, size: 26),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}