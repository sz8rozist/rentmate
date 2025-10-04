import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/flat_image.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/flat_list_provider.dart';
import '../viewmodels/flat_selector_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/custom_text_form_field.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/swipe_image_galery.dart';

/// A widget to display and manage the details of a specific flat.
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

  // Using `_retainedImages` to hold existing images and `_newImages` for newly added ones.
  // These are updated via state and then passed to the ViewModel for processing.
  List<FlatImage> _retainedImages = [];
  final List<File> _newImages = [];

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

  /// Displays a bottom sheet allowing the user to select an image source.
  Future<void> _showImageSourceActionSheet(String flatId) async {
    await showModalBottomSheet<void>(
      context: context,
      builder:
          (_) => SafeArea(
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

  /// Captures a new photo using the device camera.
  Future<void> _takePhoto(String flatId) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _newImages.add(File(pickedFile.path)));
      await _updateFlatImages(flatId);
    }
  }

  /// Picks multiple images from the device gallery.
  Future<void> _pickImages(String flatId) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    final allowedImages =
        pickedFiles.where((file) {
          final ext = file.path.toLowerCase();
          return ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.png');
        }).toList();

    // Limit to 6 images as per previous logic.
    final imagesToAdd =
        allowedImages.take(6).map((file) => File(file.path)).toList();

    setState(() => _newImages.addAll(imagesToAdd));
    await _updateFlatImages(flatId);
  }

  /// Updates the flat's images via the ViewModel.
  Future<void> _updateFlatImages(String flatId) async {
    /*await ref
        .read(flatViewModelProvider.notifier)
        .updateImage(retainedImageUrls: _retainedImages, newImages: _newImages);*/
    throw UnimplementedError("Nincs implementálva");
  }

  /// Removes a retained (existing) image from the list.
  void _removeRetainedImage(FlatImage image, String flatId) {
    setState(() => _retainedImages.removeWhere((e) => e.id == image.id));
    _updateFlatImages(flatId);
  }

  /// Removes a newly added image from the list.
  void _removeNewImage(File file, String flatId) {
    setState(() => _newImages.remove(file));
    _updateFlatImages(flatId);
  }

  /// Handles the save action for flat details.
  Future<void> _onSave(String flatId) async {
    if (!_formKey.currentState!.validate()) {
      CustomSnackBar.error(context, "Kérlek töltsd ki helyesen a mezőket!");
      return;
    }
    if (_selectedFlatStatus == null) {
      CustomSnackBar.error(context, "Válassz státuszt!");
      return;
    }
    Flat flat = Flat(
      address: _addressController.text,
      price: _priceController.text as int,
      status: _selectedFlatStatus!,
    );
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;

    await ref
        .read(flatSelectorViewModelProvider(payload?.userId).notifier)
        .updateFlat(flatId as int, flat);
    // It's generally better to pop after a successful operation is confirmed by the provider.
    if (mounted) {
      context.pop();
      CustomSnackBar.success(context, "Sikeres mentés!");
    }
  }

  /// Opens a swipeable image gallery with all images.
  void _openGallery(int initialIndex) {
    final allImages = <ImageProvider>[
      ..._retainedImages.map((e) => NetworkImage(e.url)),
      ..._newImages.map((file) => FileImage(file)),
    ];

    showSwipeImageGallery(
      context,
      initialIndex: initialIndex,
      children: allImages,
      swipeDismissible: true,
    );
  }

  /// Builds the horizontal list of flat images.
  Widget _buildImageList(String flatId) {
    final totalImages = _retainedImages.length + _newImages.length;

    if (totalImages == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Nincs feltöltött kép ehhez a lakáshoz.'),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          final bool isRetained = index < _retainedImages.length;
          final ImageProvider imageProvider;
          final VoidCallback onDelete;

          if (isRetained) {
            final image = _retainedImages[index];
            imageProvider = NetworkImage(image.url);
            onDelete = () => _removeRetainedImage(image, flatId);
          } else {
            final file = _newImages[index - _retainedImages.length];
            imageProvider = FileImage(file);
            onDelete = () => _removeNewImage(file, flatId);
          }

          return GestureDetector(
            onTap: () => _openGallery(index),
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
                  child: _buildDeleteButton(onDelete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a circular delete button for images.
  Widget _buildDeleteButton(VoidCallback onDelete) {
    return Material(
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
    );
  }

  /// Builds the list of tenants associated with the flat.
  Widget _buildTenantsList(String flatId) {
    final flatListState = ref.watch(flatViewModelProvider);
    return flatListState.when(
      data: (flat) {
        final tenantList = flat?.tenants;

        if (tenantList == null || tenantList.isEmpty) {
          return const Center(child: Text('Nincsenek bérlők hozzáadva.'));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tenantList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tenant = tenantList[index];
            return Dismissible(
              key: ValueKey(tenant.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  title: 'Biztosan törlöd?',
                  okLabel: 'Igen',
                  cancelLabel: 'Mégse',
                  isDestructiveAction: true,
                );

                if (result == OkCancelResult.ok) {
                 /* await ref
                      .read(flatViewModelProvider.notifier)
                      .removeTenant(flatId as int, tenant.id);
                  ref
                      .read(tenantListProvider.notifier)
                      .includeTenant(tenant.id);*/
                  return true;
                }
                return false;
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
      loading:
          () => Center(
            child:
                Platform.isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
          ),
      error: (error, stack) => Center(child: Text('Hiba: $error')),
    );
  }

  /// Builds a card to display a single piece of flat data.
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
            Text(
              value ?? 'Nincs megadva',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the modal content for adding a tenant.
  Widget _buildAddTenantModal(BuildContext context, String flatId) {
    String searchTerm = '';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Név szerint keresés',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  searchTerm = value.trim();
                  ref.read(tenantListProvider.notifier).loadTenants(searchTerm);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ref
                    .watch(tenantListProvider)
                    .when(
                      data: (tenants) {
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
                              onTap: () => Navigator.of(context).pop(tenant),
                            );
                          },
                        );
                      },
                      loading:
                          () => Center(
                            child:
                                Platform.isIOS
                                    ? const CupertinoActivityIndicator()
                                    : const CircularProgressIndicator(),
                          ),
                      error: (e, st) => Center(child: Text('Hiba történt: $e')),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the dialog content for editing flat details.
  Widget _buildEditFlatDialog(BuildContext context, String flatId) {
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
                  labelText: "Cím",
                  controller: _addressController,
                  validator:
                      RequiredValidator(
                        errorText: 'A cím kitöltése kötelező.',
                      ).call,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  labelText: "Ár",
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator:
                      MultiValidator([
                        RequiredValidator(
                          errorText: 'Az ár megadása kötelező!',
                        ),
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
                  items:
                      FlatStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
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
          onPressed: () {
            _onSave(flatId);
          },
          child: const Text('Mentés'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.watch(selectedFlatProvider);

    if (selectedFlat == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakás")),
      );
    }

    // Use .when or .maybeWhen for better handling of loading/error states from the provider.
    final flatStateValue = ref.watch(flatViewModelProvider);

    // Initialize controllers and selectedFlatStatus once flat data is available
    _addressController.text = selectedFlat.address;
    _priceController.text = selectedFlat.price.toString();
    _selectedFlatStatus = selectedFlat.status;
    _retainedImages = selectedFlat.images!; // Update retained images from flat data

    final List<Widget> dataCards = [
      _buildDataCard('Cím', selectedFlat.address),
      _buildDataCard('Ár (Ft)', selectedFlat.price.toString()),
      _buildDataCard('Státusz', selectedFlat.status.label),
    ];

    return SafeArea(
      child: LoadingOverlay(
        isLoading: flatStateValue.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageList(selectedFlat.id.toString()),
              const SizedBox(height: 16),
              Text(
                'Lakás adatok:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                childAspectRatio: 3 / 2,
                children: dataCards,
              ),
              const SizedBox(height: 16),
              Text('Bérlők:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildTenantsList(selectedFlat.id.toString()),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showImageSourceActionSheet(selectedFlat.id.toString());
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Kép hozzáadása'),
                ),
              ),
              const SizedBox(height: 8), // Távolság a gombok között
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final selectedTenant =
                        await showModalBottomSheet<UserModel>(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (context) =>
                                  _buildAddTenantModal(context, selectedFlat.id.toString()),
                        );

                    if (selectedTenant != null) {
                      debugPrint(
                        'Kiválasztott bérlő: ${selectedTenant.name}, email: ${selectedTenant.email}',
                      );
                      /*ref
                          .read(flatViewModelProvider.notifier)
                          .addTenant(selectedFlat.id as int, selectedTenant.id);
                      ref
                          .read(tenantListProvider.notifier)
                          .excludeTenant(selectedTenant.id);*/
                    }
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Bérlő hozzáadása'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showAdaptiveDialog(
                      context: context,
                      builder:
                          (context) => _buildEditFlatDialog(context, selectedFlat.id.toString()),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Lakás szerkesztése'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
