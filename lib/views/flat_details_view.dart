import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../viewmodels/flat_list_provider.dart';
import '../widgets/custom_text_form_field.dart';

class FlatDetailsView extends ConsumerStatefulWidget {
  final String flatId;

  const FlatDetailsView({super.key, required this.flatId});

  @override
  ConsumerState<FlatDetailsView> createState() => _FlatDetailsViewState();
}

class _FlatDetailsViewState extends ConsumerState<FlatDetailsView> {
  List<FlatImage> retainedImages = [];
  List<File> newImages = [];
  late TextEditingController addressController;
  late TextEditingController priceController;
  late Flat flat;
  FlatStatus? flatStatus;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    flat = ref
        .read(flatListProvider)
        .value!
        .firstWhere((f) => f.id == widget.flatId);
    addressController = TextEditingController(text: flat.address);
    priceController = TextEditingController(text: flat.price.toString());
    retainedImages = List.from(flat.images); // Meglévő képek megtartása
    flatStatus = flat.status;
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
      // Ha nem valid, nem mentünk tovább
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

  @override
  void dispose() {
    addressController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allImagesWidgets = <Widget>[];
    final flatState = ref.watch(flatListProvider);
    // Meglévő képek megjelenítése, törlés gombbal
    for (final image in retainedImages) {
      allImagesWidgets.add(
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 280,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => _removeRetainedImage(image),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Újonnan kiválasztott képek megjelenítése, törlés gombbal
    for (final imageFile in newImages) {
      allImagesWidgets.add(
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 280,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => _removeNewImage(imageFile),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/bg1.png', fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.4)),
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lakás részletei',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: flatState.isLoading,
        child: Container(
          height: double.infinity,
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 280,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      autoPlay: false,
                      viewportFraction: 0.8,
                    ),
                    items: allImagesWidgets,
                  ),
                  const SizedBox(height: 12),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items:
                        FlatStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          );
                        }).toList(),
                    onChanged:
                        (val) =>
                            val != null
                                ? setState(() => flatStatus = val)
                                : null,
                    validator:
                        (val) => val == null ? 'Válassz állapotot!' : null,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.save),
                      label: const Text('Mentés'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add_a_photo),
            label: 'Képek hozzáadása',
            onTap: () => _showImageSourceActionSheet(),
          ),
          SpeedDialChild(
            child: Icon(FontAwesome.user_plus),
            label: 'Albérlő hozzáadása',
            onTap: () => _pickImages(),
          ),
          // Itt adhatsz hozzá további gombokat
        ],
      ),
    );
  }
}
