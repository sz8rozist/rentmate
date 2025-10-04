import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/viewmodels/auth_viewmodel.dart';
import 'package:rentmate/viewmodels/flat_list_provider.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../models/flat_model.dart';
import '../routing/app_router.dart';
import '../viewmodels/theme_provider.dart';
import '../widgets/custom_text_form_field.dart';

class FlatFormView extends ConsumerStatefulWidget {
  const FlatFormView({super.key});

  @override
  ConsumerState<FlatFormView> createState() => _FlatFormViewState();
}

class _FlatFormViewState extends ConsumerState<FlatFormView> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();

  List<File> selectedImages = [];

  @override
  void dispose() {
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.read(selectedFlatProvider);

    final flatState =
        selectedFlat != null
            ? ref.watch(flatViewModelProvider)
            : AsyncValue<Flat?>.data(null);
    final flatVM = ref.read(flatViewModelProvider.notifier);

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
              Container(
                color:
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
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
                    'Lakás hozzáadása',
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
                  onPressed: () => {
                    context.goNamed(AppRoute.flatSelect.name),
                  },
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                CustomTextFormField(
                  controller: _addressController,
                  labelText: 'Cím',
                  validator:
                      RequiredValidator(
                        errorText: 'A cím kitöltése kötelező.',
                      ).call,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _priceController,
                  labelText: 'Ár',
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Képek kiválasztása'),
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galéria'),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    final images = await flatVM.pickImages();
                                    if (images != null) {
                                      final filtered =
                                          images.where((file) {
                                            final ext = file.path.toLowerCase();
                                            return ext.endsWith('.jpg') ||
                                                ext.endsWith('.jpeg') ||
                                                ext.endsWith('.png');
                                          }).toList();

                                      if (filtered.length +
                                              selectedImages.length >
                                          6) {
                                        CustomSnackBar.error(
                                          context,
                                          "Legfeljebb 6 képet tölthetsz fel.",
                                        );
                                        return;
                                      }

                                      setState(() {
                                        selectedImages.addAll(filtered);
                                      });
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    final photo = await flatVM.takePhoto();
                                    if (photo != null) {
                                      final ext = photo.path.toLowerCase();
                                      if (!(ext.endsWith('.jpg') ||
                                          ext.endsWith('.jpeg') ||
                                          ext.endsWith('.png'))) {
                                        CustomSnackBar.error(
                                          context,
                                          "Csak JPG vagy PNG képek engedélyezettek.",
                                        );
                                        return;
                                      }

                                      if (selectedImages.length >= 6) {
                                        CustomSnackBar.error(
                                          context,
                                          "Legfeljebb 6 képet tölthetsz fel.",
                                        );
                                        return;
                                      }

                                      setState(() {
                                        selectedImages.add(photo);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.file(
                                selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (selectedImages.isEmpty) {
                        CustomSnackBar.error(
                          context,
                          "Legalább egy képet válassz!",
                        );
                        return;
                      }
                      final authState = ref.read(authViewModelProvider);
                      final payload = authState.asData?.value.payload;

                      final addedFlat = await ref.read(flatSelectorViewModelProvider(payload?.userId).notifier).addFlat(
                        _addressController.text.trim(),
                        int.parse(_priceController.text.trim()),
                        payload?.userId,
                      );

                      print(addedFlat);
                      if (addedFlat != null) {
                        final flatId = addedFlat.id;
                        await ref.read(flatSelectorViewModelProvider(payload?.userId).notifier).uploadImages(
                          flatId as int,
                          selectedImages.map((file) => file.path).toList(),
                        );
                      } else {
                        CustomSnackBar.error(
                          context,
                          "Hiba történt a lakás hozzáadásakor.",
                        );
                      }

                      // Visszairányítás
                      context.goNamed(AppRoute.flatSelect.name);
                    }
                  },
                  child: const Text('Mentés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
