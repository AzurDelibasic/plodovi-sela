import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../farms/domain/entities/farm_image.dart';
import '../../../farms/presentation/providers/farms_providers.dart';
import '../../../listings/presentation/providers/listings_providers.dart';

const _maxFarmImages = 6;

/// Lets a seller edit their public storefront: display name, avatar, short
/// bio and city. Only reachable from [ProfileScreen] for a `prodavac`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _farmNameController;
  late final TextEditingController _bioController;
  int? _cityId;
  Uint8List? _newAvatarBytes;
  bool _isSubmitting = false;
  bool _initialized = false;
  bool _isUploadingGallery = false;

  @override
  void dispose() {
    _farmNameController.dispose();
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

  Future<void> _addGalleryImages(int remainingSlots) async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() => _isUploadingGallery = true);
    for (final file in picked.take(remainingSlots)) {
      final bytes = await file.readAsBytes();
      final result = await ref
          .read(farmsRepositoryProvider)
          .addFarmImage(bytes);
      if (!mounted) return;
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        AppToast.show(context, message: failure.message);
        break;
      }
    }
    if (!mounted) return;
    setState(() => _isUploadingGallery = false);
    ref.invalidate(myFarmImagesProvider);
  }

  Future<void> _removeGalleryImage(FarmImage image) async {
    final result = await ref
        .read(farmsRepositoryProvider)
        .removeFarmImage(image.id);
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.show(context, message: failure.message),
      (_) => ref.invalidate(myFarmImagesProvider),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(updateProfileUseCaseProvider)
        .call(
          farmName: _farmNameController.text.trim(),
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
      _farmNameController = TextEditingController(text: user.farmName ?? '');
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
                                      Icons.person_outline,
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
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Vaša profilna slika (lična, ne farma)',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.surfaceColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _farmNameController,
                      decoration: InputDecoration(
                        labelText: 'Naziv farme',
                        helperText: user?.fullName == null
                            ? 'Ostavi prazno da koristiš svoje registrovano ime.'
                            : 'Ostavi prazno da koristiš ime naloga: ${user!.fullName}',
                        helperMaxLines: 2,
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
                    const SizedBox(height: 24),
                    Text(
                      'Galerija farme',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ove slike se prikazuju na kartici farme — odvojene su '
                      'od vaše profilne slike.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.surfaceColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FarmGallery(
                      isUploading: _isUploadingGallery,
                      onAdd: _addGalleryImages,
                      onRemove: _removeGalleryImage,
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

class _FarmGallery extends ConsumerWidget {
  const _FarmGallery({
    required this.isUploading,
    required this.onAdd,
    required this.onRemove,
  });

  final bool isUploading;
  final void Function(int remainingSlots) onAdd;
  final void Function(FarmImage image) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(myFarmImagesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColors = context.surfaceColors;

    return imagesAsync.when(
      loading: () => const SizedBox(
        height: 84,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => Text(
        'Nije uspjelo učitavanje galerije.',
        style: TextStyle(color: surfaceColors.textMuted),
      ),
      data: (images) {
        final remainingSlots = _maxFarmImages - images.length;
        return SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final image in images)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: image.url,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: surfaceColors.textPrimary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onRemove(image),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (remainingSlots > 0)
                Material(
                  color: surfaceColors.background,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isUploading ? null : () => onAdd(remainingSlots),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: surfaceColors.outline),
                      ),
                      child: isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add_photo_alternate_outlined,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
