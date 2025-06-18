import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';
import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../viewmodels/flat_list_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/custom_text_form_field.dart';

class FlatDetailsView extends ConsumerStatefulWidget {
  final String flatId;

  const FlatDetailsView({super.key, required this.flatId});

  @override
  ConsumerState<FlatDetailsView> createState() => _FlatDetailsViewState();
}

class _FlatDetailsViewState extends ConsumerState<FlatDetailsView>
    with SingleTickerProviderStateMixin {
  List<FlatImage> retainedImages = [];
  List<File> newImages = [];
  late TextEditingController addressController;
  late TextEditingController priceController;
  late Flat flat;
  FlatStatus? flatStatus;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    flat = ref
        .read(flatListProvider)
        .value!
        .firstWhere((f) => f.id == widget.flatId);
    addressController = TextEditingController(text: flat.address);
    priceController = TextEditingController(text: flat.price.toString());
    retainedImages = List.from(flat.images);
    flatStatus = flat.status;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galéria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        newImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      final allowed =
          pickedFiles.where((x) {
            final p = x.path.toLowerCase();
            return p.endsWith('.jpg') ||
                p.endsWith('.jpeg') ||
                p.endsWith('.png');
          }).toList();

      final limited = allowed.length > 6 ? allowed.sublist(0, 6) : allowed;

      setState(() {
        newImages.addAll(limited.map((x) => File(x.path)));
      });
    }
  }

  void _removeRetainedImage(FlatImage image) {
    setState(() {
      retainedImages.removeWhere((e) => e.id == image.id);
    });
  }

  void _removeNewImage(File image) {
    setState(() {
      newImages.remove(image);
    });
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
          flatId: flat.id!,
          address: addressController.text,
          price: priceController.text,
          retainedImageUrls: retainedImages,
          newImages: newImages,
          status: flatStatus!,
        );

    CustomSnackBar.success("Lakás sikeresen frissítve!");
    Navigator.of(context).pop();
  }

  void _openGallery(int initialIndex) {
    final allImages = [
      ...retainedImages.map(
        (e) => Image.network(e.imageUrl, fit: BoxFit.contain),
      ),
      ...newImages.map((file) => Image.file(file, fit: BoxFit.contain)),
    ];

    SwipeImageGallery(
      context: context,
      children: allImages,
      initialIndex: initialIndex,
    ).show();
  }

  @override
  void dispose() {
    addressController.dispose();
    priceController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  // Példa egy egyszerű bérlőlista widget
  Widget _buildTenantsList() {
    if (flat.tenants == null || flat.tenants!.isEmpty) {
      return const Text('Nincsenek bérlők hozzáadva.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flat.tenants?.length,
      itemBuilder: (context, index) {
        final tenant = flat.tenants![index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(tenant.name),
          subtitle: Text(tenant.email),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Itt pl. törlés vagy eltávolítás a bérlők közül
              setState(() {
                flat.tenants?.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatState = ref.watch(flatListProvider);
    final allImagesCount = retainedImages.length + newImages.length;

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
              Image.asset('assets/images/bg1.png', fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.4)),
              // A tartalmat beljebb húzzuk, hogy ne lógjon be a status bar területére
              Padding(
                padding: EdgeInsets.fromLTRB(60, MediaQuery.of(context).padding.top, 16, 0),
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
        isLoading: flatState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImagesCount,
                    itemBuilder: (context, index) {
                      Widget imageWidget;
                      VoidCallback onDelete;

                      if (index < retainedImages.length) {
                        final image = retainedImages[index];
                        imageWidget = Image.network(
                          image.imageUrl,
                          fit: BoxFit.cover,
                          width: 200,
                        );
                        onDelete = () => _removeRetainedImage(image);
                      } else {
                        final imageFile =
                            newImages[index - retainedImages.length];
                        imageWidget = Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          width: 200,
                        );
                        onDelete = () => _removeNewImage(imageFile);
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
                ),
                const SizedBox(height: 25),
                CustomTextFormField(
                  controller: addressController,
                  labelText: 'Cím',
                  validator:
                      RequiredValidator(
                        errorText: 'A cím kitöltése kötelező.',
                      ).call,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: priceController,
                  labelText: 'Ár',
                  keyboardType: TextInputType.number,
                  validator:
                      MultiValidator([
                        RequiredValidator(
                          errorText: 'Az ár kitöltése kötelező.',
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
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      FlatStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                  onChanged: (val) => setState(() => flatStatus = val),
                  validator: (val) => val == null ? 'Válassz állapotot!' : null,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bérlők:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTenantsList(),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    child: const Text("Mentés"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionBubble(
        items: <Bubble>[
          Bubble(
            title: "Kép hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.add_a_photo,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _showImageSourceActionSheet();
              _animationController.reverse();
            },
          ),
          Bubble(
            title: "Bérlő hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: FontAwesome.user_plus,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
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
                        final tenantListState = ref.watch(tenantListProvider);

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
                              child: tenantListState.when(
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
                }
              });

              _animationController.reverse();
            },
          ),
        ],
        animation: _animation,
        onPress:
            () =>
                _animationController.isCompleted
                    ? _animationController.reverse()
                    : _animationController.forward(),
        iconColor: Colors.white,
        iconData: Icons.add,
        backGroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onDelete) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
    );
  }
}
