import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';
import 'package:rentmate/widgets/loading_overlay.dart';

import '../models/flat_image.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../viewmodels/flat_list_provider.dart';
import '../viewmodels/theme_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/swipe_image_galery.dart';

class FlatDetailsView extends ConsumerStatefulWidget {
  final String flatId;

  const FlatDetailsView({super.key, required this.flatId});

  @override
  ConsumerState<FlatDetailsView> createState() => _FlatDetailsViewState();
}

class _FlatDetailsViewState extends ConsumerState<FlatDetailsView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController addressController;
  late final TextEditingController priceController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late Flat _flat;
  late FlatStatus? flatStatus;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<FlatImage> _retainedImages = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    final flatList = ref.read(flatListProvider).value ?? [];
    _flat = flatList.firstWhere((f) => f.id == widget.flatId);

    addressController = TextEditingController(text: _flat.address);
    priceController = TextEditingController(text: _flat.price.toString());

    _retainedImages = List.from(_flat.images);
    flatStatus = _flat.status;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceActionSheet() async {
    await showModalBottomSheet(
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
                    _pickImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _newImages.add(File(pickedFile.path)));
      ref.read(flatListProvider.notifier).updateImage(flatId: widget.flatId, retainedImageUrls: _retainedImages, newImages: _newImages);
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    final allowed =
        pickedFiles.where((file) {
          final ext = file.path.toLowerCase();
          return ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.png');
        }).toList();

    final limited = allowed.length > 6 ? allowed.sublist(0, 6) : allowed;

    setState(() => _newImages.addAll(limited.map((file) => File(file.path))));
    ref.read(flatListProvider.notifier).updateImage(flatId: widget.flatId, retainedImageUrls: _retainedImages, newImages: _newImages);
  }

  void _removeRetainedImage(FlatImage image) {
    setState(() => _retainedImages.removeWhere((e) => e.id == image.id));
    ref.read(flatListProvider.notifier).updateImage(flatId: widget.flatId, retainedImageUrls: _retainedImages, newImages: _newImages);
  }

  void _removeNewImage(File file) {
    setState(() => _newImages.remove(file));
    ref.read(flatListProvider.notifier).updateImage(flatId: widget.flatId, retainedImageUrls: _retainedImages, newImages: _newImages);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.error("Kérlek töltsd ki helyesen a mezőket!"),
      );
      return;
    }
    if (flatStatus == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar.error("Válassz státuszt!"));
      return;
    }

    await ref
        .read(flatListProvider.notifier)
        .updateFlat(
          flatId: _flat.id!,
          address: addressController.text,
          price: priceController.text,
          status: flatStatus!,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(CustomSnackBar.success("Sikeres mentés!"));
  }

  void _openGallery(int initialIndex) {
    final allImages = <ImageProvider>[
      ..._retainedImages.map((e) => NetworkImage(e.imageUrl)),
      ..._newImages.map((file) => FileImage(file)),
    ];

    showSwipeImageGallery(
      context,
      initialIndex: initialIndex,
      children: allImages,
      swipeDismissible: true,
    );
  }

  Widget _buildImageList() {
    final totalImages = _retainedImages.length + _newImages.length;
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          final bool isRetained = index < _retainedImages.length;

          final Widget imageWidget =
              isRetained
                  ? Image.network(
                    _retainedImages[index].imageUrl,
                    fit: BoxFit.cover,
                    width: 200,
                  )
                  : Image.file(
                    _newImages[index - _retainedImages.length],
                    fit: BoxFit.cover,
                    width: 200,
                  );

          final VoidCallback onDelete =
              isRetained
                  ? () => _removeRetainedImage(_retainedImages[index])
                  : () => _removeNewImage(
                    _newImages[index - _retainedImages.length],
                  );

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
                    child: imageWidget,
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

  Widget _buildTenantsList() {
    final flatListState = ref.watch(flatListProvider);
    return flatListState.when(
      data: (flats) {
        final flatToDisplay = flats.firstWhere((f) => f.id == widget.flatId);
        final tenantList = flatToDisplay.tenants;

        if (tenantList == null || tenantList.isEmpty) {
          return const Text('Nincsenek bérlők hozzáadva.');
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
              direction: DismissDirection.endToStart, // jobbról balra swipe a törléshez
              confirmDismiss: (direction) async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  title: 'Biztosan törlöd?',
                  okLabel: 'Igen',
                  cancelLabel: 'Mégse',
                  isDestructiveAction: true,
                );

                if (result == OkCancelResult.ok) {
                  await ref.read(flatListProvider.notifier).removeTenantFromFlat(widget.flatId, tenant.id);
                  ref.read(tenantListProvider.notifier).includeTenant(tenant.id);

                  return true; // ténylegesen törölje az elemet a listából
                } else {
                  return false; // ne törölje, maradjon az elem
                }
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
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Text('Hiba: $error'),
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
            Text(
              value ?? 'Nincs megadva',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatList = ref.watch(flatListProvider);
    final flat = flatList.value?.firstWhere((f) => f.id == widget.flatId);

    final fabTheme = Theme.of(context).floatingActionButtonTheme;

    final List<Widget> dataCards = [
      _buildDataCard('Cím', flat?.address),
      _buildDataCard('Ár (Ft)', flat?.price.toString()),
      _buildDataCard('Státusz', flat?.status.label),
    ];
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          // A háttér lefedi a státusz sávot is
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/header-image.png', fit: BoxFit.cover),
              Container(color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              ),
              // A tartalmat beljebb húzzuk, hogy ne lógjon be a status bar területére
              Padding(
                padding: EdgeInsets.fromLTRB(
                  60,
                  MediaQuery.of(context).padding.top,
                  16,
                  0,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Lakás adatai',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: ref.watch(flatListProvider).isLoading,
        child: SafeArea(
          top: true,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageList(),
                const SizedBox(height: 16),
                Text('Lakás adatok:', style: Theme.of(context).textTheme.titleMedium),
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
                _buildTenantsList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionBubble(
        animation: _animation,
        items: [
          Bubble(
            title: "Kép hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.add_a_photo,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            onPress: () {
              _animationController.reverse();
              _showImageSourceActionSheet();
            },
          ),
          Bubble(
            title: "Albérlő hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.person_add,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            onPress: () async {
              final tenantListNotifier = ref.read(tenantListProvider.notifier);

              await showModalBottomSheet<UserModel>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
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
                              decoration: InputDecoration(
                                labelText: 'Név szerint keresés',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                searchTerm = value.trim();
                                tenantListNotifier.loadTenants(searchTerm);
                              },
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: ref.watch(tenantListProvider).when(
                                data: (tenants) {
                                  if (tenants.isEmpty) {
                                    return Center(child: Text('Nincs találat'));
                                  }
                                  return ListView.builder(
                                    itemCount: tenants.length,
                                    itemBuilder: (context, index) {
                                      final tenant = tenants[index];
                                      return ListTile(
                                        title: Text(tenant.name),
                                        subtitle: Text(tenant.email),
                                        onTap: () {
                                          Navigator.of(context).pop(tenant);
                                        },
                                      );
                                    },
                                  );
                                },
                                loading:
                                    () => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                error:
                                    (e, st) =>
                                        Center(child: Text('Hiba történt: $e')),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ).then((selectedTenant) {
                if (selectedTenant != null) {
                  print(
                    'Kiválasztott bérlő: ${selectedTenant.name}, email: ${selectedTenant.email}',
                  );
                  ref
                      .read(flatListProvider.notifier)
                      .addTenantToFlat(widget.flatId, selectedTenant.id);
                  ref.read(tenantListProvider.notifier).excludeTenant(selectedTenant.id);
                }
              });

              _animationController.reverse();
            },
          ),
          Bubble(
            title: "Lakás szerkesztése",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.edit,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            onPress: () async {
              _animationController.reverse();

              await showAdaptiveDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Lakás szerkesztése'),
                    content: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400, minWidth: 300),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomTextFormField(
                                labelText: "Cím",
                                controller: addressController,
                                validator:
                                RequiredValidator(
                                  errorText: 'A cím kitöltése kötelező.',
                                ).call,
                              ),
                              const SizedBox(height: 12),
                              CustomTextFormField(
                                labelText: "Ár",
                                controller: priceController,
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
                                value: flatStatus,
                                decoration: InputDecoration(
                                  labelText: 'Állapot',
                                ),
                                items:
                                    FlatStatus.values.map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status.label),
                                      );
                                    }).toList(),
                                onChanged:
                                    (val) => setState(() => flatStatus = val),
                                validator:
                                    (val) =>
                                        val == null
                                            ? 'Válassz állapotot!'
                                            : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Mégse'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _onSave();
                        },
                        child: Text('Mentés'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        onPress: () {
          if (_animationController.status == AnimationStatus.completed) {
            _animationController.reverse();
          } else {
            _animationController.forward();
          }
        },
        iconColor: fabTheme.foregroundColor ?? Colors.white,
        animatedIconData: AnimatedIcons.menu_close,
        backGroundColor: fabTheme.backgroundColor ?? Colors.white,
      ),
    );
  }
}
