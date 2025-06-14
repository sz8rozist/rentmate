import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
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
  }
  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galéria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      if (source == ImageSource.gallery) {
        await _pickImages();
      } else if (source == ImageSource.camera) {
        await _takePicture();
      }
    }
  }

  Future<void> _takePicture() async {
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
      // Szűrés, max 6 új kép (vagy igény szerint)
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
        CustomSnackBar.error("Kérlek töltsd ki helyesen a mezőket!")
      );
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
          status: ref.read(flatListProvider.notifier).flatStatus!,
        );

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
                    color: Colors.black.withOpacity(0.5),
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
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                        RequiredValidator(errorText: 'Az ár kitöltése kötelező.'),
                        PatternValidator(
                          r'^\d+$',
                          errorText: 'Az ár csak szám lehet!',
                        ),
                      ]).call,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FlatStatus>(
                  value: ref.watch(flatListProvider.notifier).flatStatus,
                  decoration: InputDecoration(
                    labelText: 'Állapot',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: FlatStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (val) => val != null ? ref.read(flatListProvider.notifier).setFlatStatus(val) : null,
                  validator: (val) => val == null ? 'Válassz állapotot!' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceOptions,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Képek hozzáadása'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
    );
  }
}
