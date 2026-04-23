import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/viewmodels/apartman_provider.dart';

import '../models/flat_image.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/flat_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/custom_text_form_field.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/swipe_image_galery.dart';

class FlatDetailsView extends ConsumerStatefulWidget {
  const FlatDetailsView({super.key});

  @override
  ConsumerState<FlatDetailsView> createState() => _FlatDetailsViewState();
}

class _FlatDetailsViewState extends ConsumerState<FlatDetailsView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  FlatStatus? _selectedFlatStatus;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<FlatImage> _retainedImages = [];
  final List<File> _newImages = [];

  // Az initState-ben egyszer töltjük fel a controllereket
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _addressController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Inicializálás (egyszer fut le, amikor a flat először elérhető)
  // ---------------------------------------------------------------------------

  void _initFromFlat(Flat flat) {
    if (_initialized) return;
    _initialized = true;
    _addressController.text = flat.address;
    _priceController.text = flat.price.toString();
    _selectedFlatStatus = flat.status;
    _retainedImages = List.from(flat.images ?? []);
  }

  // ---------------------------------------------------------------------------
  // Képkezelés
  // ---------------------------------------------------------------------------

  Future<void> _showImageSourceActionSheet(int flatId) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galéria'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(flatId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(flatId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(int flatId) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() => _newImages.add(File(picked.path)));
    await _uploadNewImages(flatId);
  }

  Future<void> _pickImages(int flatId) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final allowed = picked
        .where((f) {
      final ext = f.path.toLowerCase();
      return ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png');
    })
        .take(6)
        .map((f) => File(f.path))
        .toList();

    if (allowed.isEmpty) return;
    setState(() => _newImages.addAll(allowed));
    await _uploadNewImages(flatId);
  }

  Future<void> _uploadNewImages(int flatId) async {
    if (_newImages.isEmpty) return;
    final paths = _newImages.map((f) => f.path).toList();
    await ref
        .read(flatViewModelProvider.notifier).uploadImages(flatId, paths);
    setState(() => _newImages.clear());
  }

  Future<void> _removeRetainedImage(FlatImage image, int flatId) async {
    setState(() => _retainedImages.removeWhere((e) => e.id == image.id));
    await ref
        .read(flatViewModelProvider.notifier)
        .deleteImage(flatId, image.id as int);
  }

  void _removeNewImage(File file) {
    setState(() => _newImages.remove(file));
  }

  void _openGallery(int initialIndex) {
    final allImages = <ImageProvider>[
      ..._retainedImages
          .where((e) => e.url != null && e.url!.isNotEmpty)
          .map((e) => NetworkImage(e.url!)),
      ..._newImages.map((f) => FileImage(f)),
    ];
    if (allImages.isEmpty) return;

    showSwipeImageGallery(
      context,
      initialIndex: initialIndex,
      children: allImages,
      swipeDismissible: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Mentés
  // ---------------------------------------------------------------------------

  Future<void> _onSave(int flatId) async {
    if (!_formKey.currentState!.validate()) {
      CustomSnackBar.error(context, 'Kérlek töltsd ki helyesen a mezőket!');
      return;
    }
    if (_selectedFlatStatus == null) {
      CustomSnackBar.error(context, 'Válassz státuszt!');
      return;
    }


    await ref
        .read(apartmentProvider.notifier)
        .updateFlat(
      flatId,
      _addressController.text,
      int.parse(_priceController.text),
      _selectedFlatStatus!,
    );

    if (mounted) {
      context.pop();
      CustomSnackBar.success(context, 'Sikeres mentés!');
    }
  }

  // ---------------------------------------------------------------------------
  // UI builders
  // ---------------------------------------------------------------------------

  Widget _buildImageList(int flatId) {
    final totalImages = _retainedImages.length + _newImages.length;

    if (totalImages == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Nincs feltöltött kép ehhez a lakáshoz.'),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          final isRetained = index < _retainedImages.length;

          if (isRetained) {
            final image = _retainedImages[index];
            if (image.url == null || image.url!.isEmpty) {
              return const SizedBox.shrink();
            }
            return _ImageTile(
              imageProvider: NetworkImage(image.url!),
              onTap: () => _openGallery(index),
              onDelete: () => _removeRetainedImage(image, flatId),
            );
          } else {
            final file = _newImages[index - _retainedImages.length];
            return _ImageTile(
              imageProvider: FileImage(file),
              onTap: () => _openGallery(index),
              onDelete: () => _removeNewImage(file),
            );
          }
        },
      ),
    );
  }

  Widget _buildTenantsList(int flatId) {
    final flatState = ref.watch(flatViewModelProvider);

    return flatState.when(
      loading: () => Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      ),
      error: (e, _) => Center(child: Text('Hiba: $e')),
      data: (flat) {
        final tenants = flat.flat?.tenants ?? [];

        if (tenants.isEmpty) {
          return const Center(child: Text('Nincsenek bérlők hozzáadva.'));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tenants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tenant = tenants[index];
            return Dismissible(
              key: ValueKey(tenant.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  title: 'Biztosan törlöd?',
                  okLabel: 'Igen',
                  cancelLabel: 'Mégse',
                  isDestructiveAction: true,
                );
                if (result != OkCancelResult.ok) return false;

                await ref
                    .read(flatViewModelProvider.notifier)
                    .removeTenant(tenant.id as int);
                ref
                    .read(tenantListProvider.notifier)
                    .includeTenant(tenant.id as int);
                return true;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: Text(tenant.name),
                  subtitle: Text(tenant.email),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddTenantModal(BuildContext context, int flatId) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final tenantState = ref.watch(tenantListProvider);
          final flatNotifier = ref.read(flatViewModelProvider.notifier);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Név szerint keresés',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    ref.read(tenantListProvider.notifier).search(value.trim()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: tenantState.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Hiba: $e')),
                  data: (state) {
                    final tenants = state.visibleTenants;
                    if (tenants.isEmpty) {
                      return const Center(child: Text('Nincs találat'));
                    }
                    return ListView.builder(
                      itemCount: tenants.length,
                      itemBuilder: (context, index) {
                        final tenant = tenants[index];
                        return ListTile(
                          title: Text(tenant.name),
                          subtitle: Text(tenant.email),
                          onTap: () async {
                            await flatNotifier.addTenant(tenant);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditFlatDialog(BuildContext context, int flatId) {
    return AlertDialog(
      title: const Text('Lakás szerkesztése'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextFormField(
                  labelText: 'Cím',
                  controller: _addressController,
                  validator: RequiredValidator(
                    errorText: 'A cím kitöltése kötelező.',
                  ).call,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  labelText: 'Ár',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Az ár megadása kötelező!'),
                    PatternValidator(
                      r'^\d+$',
                      errorText: 'Az ár csak szám lehet!',
                    ),
                  ]).call,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FlatStatus>(
                  value: _selectedFlatStatus,
                  decoration: const InputDecoration(labelText: 'Állapot'),
                  items: FlatStatus.values
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label),
                  ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFlatStatus = val),
                  validator: (val) => val == null ? 'Válassz állapotot!' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        ElevatedButton(
          onPressed: () => _onSave(flatId),
          child: const Text('Mentés'),
        ),
      ],
    );
  }

  Widget _buildDataCard(String label, String? value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(value ?? 'Nincs megadva',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.watch(apartmentProvider);

    if (selectedFlat.active == null) {
      return const Scaffold(
        body: Center(child: Text('Nincs kiválasztott lakás')),
      );
    }

    // Egyszer inicializáljuk a controllereket
    _initFromFlat(selectedFlat.active as Flat);

    final flatState = ref.watch(flatViewModelProvider);

    return SafeArea(
      child: LoadingOverlay(
        isLoading: flatState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageList(selectedFlat.active?.id as int),
              const SizedBox(height: 16),
              Text('Lakás adatok:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                childAspectRatio: 3 / 2,
                children: [
                  _buildDataCard('Cím', selectedFlat.active?.address),
                  _buildDataCard('Ár (Ft)', selectedFlat.active?.price.toString()),
                  _buildDataCard('Státusz', selectedFlat.active?.status.label),
                ],
              ),
              const SizedBox(height: 16),
              Text('Bérlők:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildTenantsList(selectedFlat.active?.id as int),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.add_a_photo,
                label: 'Kép hozzáadása',
                onPressed: () =>
                    _showImageSourceActionSheet(selectedFlat.active?.id as int),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.person_add,
                label: 'Bérlő hozzáadása',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) =>
                      _buildAddTenantModal(ctx, selectedFlat.active?.id as int),
                ),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.edit,
                label: 'Lakás szerkesztése',
                onPressed: () => showAdaptiveDialog<void>(
                  context: context,
                  builder: (ctx) =>
                      _buildEditFlatDialog(ctx, selectedFlat.active?.id as int),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgetek
// ---------------------------------------------------------------------------

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.imageProvider,
    required this.onTap,
    required this.onDelete,
  });

  final ImageProvider imageProvider;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 250,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: 200,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black38,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}