import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../listings/presentation/providers/listings_providers.dart';

/// Lets a seller edit their public storefront: display name, avatar, short
/// bio and city. Only reachable from [ProfileScreen] for a `prodavac`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  int? _cityId;
  Uint8List? _newAvatarBytes;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _newAvatarBytes = bytes);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(updateProfileUseCaseProvider)
        .call(
          fullName: _nameController.text,
          bio: _bioController.text.trim(),
          cityId: _cityId,
          avatarBytes: _newAvatarBytes,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      _,
    ) {
      AppToast.show(
        context,
        type: AppToastType.success,
        message: 'Profil je ažuriran.',
      );
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final citiesAsync = ref.watch(citiesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!_initialized && user != null) {
      _nameController = TextEditingController(text: user.fullName ?? '');
      _bioController = TextEditingController(text: user.bio ?? '');
      _cityId = user.cityId;
      _initialized = true;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Uredi profil farme',
              leading: HeaderIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Nazad',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (!_initialized)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              backgroundImage: _newAvatarBytes != null
                                  ? MemoryImage(_newAvatarBytes!)
                                  : (user?.avatarUrl != null
                                        ? NetworkImage(user!.avatarUrl!)
                                        : null),
                              child:
                                  _newAvatarBytes == null &&
                                      user?.avatarUrl == null
                                  ? Icon(
                                      Icons.agriculture_outlined,
                                      color: colorScheme.primary,
                                      size: 36,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: colorScheme.primary,
                                shape: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Naziv farme / ime',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Kratak opis (opciono)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    citiesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (cities) => DropdownButtonFormField<int>(
                        initialValue: _cityId,
                        decoration: const InputDecoration(labelText: 'Grad'),
                        items: [
                          for (final city in cities)
                            DropdownMenuItem(
                              value: city.id,
                              child: Text(city.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _cityId = value),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sačuvaj'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
