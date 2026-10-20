import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/sync/sync_manager.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;

  File? _pickedPhoto;
  bool _removePhoto = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (image == null || !mounted) return;
      setState(() {
        _pickedPhoto = File(image.path);
        _removePhoto = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnack.error(context, 'Could not open photos: ${friendlyError(e)}');
      }
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.lost),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.lost),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _pickedPhoto = null;
                    _removePhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final profileSync = context.read<SyncManager>().profileSyncService;
    final user = authProvider.user;
    final newName = _nameController.text.trim();

    setState(() => _isSaving = true);
    try {
      String? photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await CloudinaryService().uploadImage(_pickedPhoto!);
      } else if (_removePhoto) {
        photoUrl = '';
      }

      final nameChanged = newName != user?.displayName;
      await authProvider.updateProfile(
        displayName: nameChanged ? newName : null,
        photoUrl: photoUrl,
      );

      // Update the name/photo on their existing posts, claims and messages too.
      var activityUpdated = true;
      if ((nameChanged || photoUrl != null) && user != null) {
        activityUpdated = await profileSync.applyNameChange(user.uid);
      }
      if (!mounted) return;
      if (activityUpdated) {
        AppSnack.success(context, 'Profile updated.');
      } else {
        AppSnack.info(
          context,
          'Profile updated. Your older posts and messages will show the new '
          'name once you are back online.',
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppSnack.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currentPhoto = _removePhoto ? null : user?.photoURL;
    final hasPhoto =
        _pickedPhoto != null || (currentPhoto?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Stack(
                children: [
                  ProfileAvatar(
                    radius: 55,
                    photoUrl: currentPhoto,
                    localFile: _pickedPhoto,
                    name: _nameController.text,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Change photo',
                        onPressed:
                            _isSaving ? null : () => _showPhotoOptions(hasPhoto),
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Please enter your name.';
                if (name.length < 2) return 'Name is too short.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: user?.email ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'Your email is used to sign in and cannot be changed.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Changing your name also updates it on your existing posts, '
              'claims and messages.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
