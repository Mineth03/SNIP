import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../repositories/profile_repository.dart';
import '../../../repositories/storage_repository.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/snip_card.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';
import '../../auth/providers/auth_providers.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(SnipSpacing.md),
        children: [
          SnipCard(
            child: Row(
              children: [
                SnipAvatar(
                  imageUrl: profile?.avatarUrl,
                  name: profile?.fullName,
                  size: 64,
                ),
                const SizedBox(width: SnipSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Guest',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        profile?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SnipSpacing.md),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          const ThemeModeListTile(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: SnipColors.error),
            title: const Text(
              'Sign out',
              style: TextStyle(color: SnipColors.error),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  String? _avatarUrl;
  Uint8List? _previewBytes;
  bool _uploadingImage = false;
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  void _hydrateIfNeeded() {
    if (_hydrated) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;
    _name.text = profile.fullName;
    _phone.text = profile.phone ?? '';
    _city.text = profile.city ?? '';
    _avatarUrl = profile.avatarUrl;
    _hydrated = true;
  }

  Future<void> _pickAndUploadImage() async {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _uploadingImage = true;
      });

      final extension = file.name.split('.').last.toLowerCase();
      final url = await ref.read(storageRepositoryProvider).uploadAvatar(
            bytes: bytes,
            userId: profile.id,
            fileExtension: extension.isNotEmpty ? extension : 'jpg',
          );

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _uploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar uploaded! Tap Save to keep changes.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            id: profile.id,
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            city: _city.text.trim(),
            avatarUrl: _avatarUrl,
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentProfileProvider);
    _hydrateIfNeeded();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SnipSpacing.lg),
        child: Column(
          children: [
            // Avatar picker
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: SnipColors.background,
                    backgroundImage: _previewBytes != null
                        ? MemoryImage(_previewBytes!)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!) as ImageProvider
                            : null),
                    child: (_previewBytes == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 48, color: SnipColors.textMuted)
                        : null,
                  ),
                  if (_uploadingImage)
                    const Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor: Colors.black38,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Material(
                    color: SnipColors.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SnipSpacing.xl),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: SnipSpacing.md),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: SnipSpacing.md),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: SnipSpacing.xl),
            PrimaryCTA(label: 'Save Changes', isLoading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
