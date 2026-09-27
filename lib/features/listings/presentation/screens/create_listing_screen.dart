import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/screen_header.dart';
import '../providers/listings_providers.dart';

const _units = ['kom', 'kg', 'g', 'l', 'ml', 'gajba', 'vreća'];
const _maxImages = 5;

/// Publish-a-new-listing form, reachable only by a signed-in `prodavac`
/// (enforced both by the entry point that pushes this route and,
/// authoritatively, by the `listings_insert_own_as_seller` RLS policy).
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _unit = _units.first;
  int? _categoryId;
  int? _cityId;
  bool _isOrganic = false;
  bool _pickupAvailable = true;
  bool _deliveryAvailable = false;
  final _images = <Uint8List>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final bytes = await Future.wait(picked.take(remaining).map((f) => f.readAsBytes()));
    setState(() => _images.addAll(bytes));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_pickupAvailable && !_deliveryAvailable) {
      AppToast.show(
        context,
        message: 'Izaberite bar jedan način preuzimanja.',
      );
      return;
    }
    if (_categoryId == null || _cityId == null) {
      AppToast.show(context, message: 'Izaberite kategoriju i grad.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(listingsRepositoryProvider)
        .createListing(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          unit: _unit,
          categoryId: _categoryId!,
          cityId: _cityId!,
          isOrganic: _isOrganic,
          pickupAvailable: _pickupAvailable,
          deliveryAvailable: _deliveryAvailable,
          images: _images,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      _,
    ) {
      ref.invalidate(activeListingsProvider);
      AppToast.show(
        context,
        type: AppToastType.success,
        message: 'Oglas je objavljen.',
      );
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Novi oglas',
              leading: HeaderIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Nazad',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text(
                      'Fotografije',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    _ImagePicker(images: _images, onAdd: _pickImages, onRemove: (i) {
                      setState(() => _images.removeAt(i));
                    }),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Naziv'),
                      validator: (value) =>
                          (value == null || value.trim().length < 3)
                          ? 'Unesite naziv (bar 3 karaktera).'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Opis (opciono)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cijena (KM)',
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').trim(),
                              );
                              if (parsed == null || parsed < 0) {
                                return 'Unesite ispravnu cijenu.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _unit,
                            decoration: const InputDecoration(
                              labelText: 'Jedinica',
                            ),
                            items: [
                              for (final unit in _units)
                                DropdownMenuItem(value: unit, child: Text(unit)),
                            ],
                            onChanged: (value) =>
                                setState(() => _unit = value ?? _unit),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    categoriesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (categories) => DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategorija',
                        ),
                        items: [
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                        validator: (value) =>
                            value == null ? 'Obavezno polje.' : null,
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
                        validator: (value) =>
                            value == null ? 'Obavezno polje.' : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Organski proizvod'),
                      value: _isOrganic,
                      onChanged: (value) => setState(() => _isOrganic = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Preuzimanje'),
                      value: _pickupAvailable,
                      onChanged: (value) =>
                          setState(() => _pickupAvailable = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dostava'),
                      value: _deliveryAvailable,
                      onChanged: (value) =>
                          setState(() => _deliveryAvailable = value),
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
                            : const Text('Objavi oglas'),
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

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColors = context.surfaceColors;

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (index, image) in images.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      image,
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
                        onTap: () => onRemove(index),
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
          if (images.length < _maxImages)
            Material(
              color: surfaceColors.background,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onAdd,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: surfaceColors.outline),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
