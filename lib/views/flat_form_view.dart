import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/viewmodels/apartman_provider.dart';
import 'package:rentmate/viewmodels/auth_viewmodel.dart';
import 'package:rentmate/viewmodels/flat_viewmodel.dart';
import 'package:rentmate/widgets/app_bar.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../models/flat_model.dart';
import '../routing/app_router.dart';
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
    final selectedFlat = ref.read(apartmentProvider);

    final flatState =
        selectedFlat.active != null
            ? ref.watch(flatViewModelProvider)
            : AsyncValue<Flat?>.data(null);
    final flatVM = ref.read(flatViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBarWidget(
        onBack: () => context.goNamed(AppRoute.home.name),
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

                      await ref.read(apartmentProvider.notifier).addFlat(_addressController.text.trim(),
                        int.parse(_priceController.text.trim()),
                        payload?.userId as int);

                      // Visszairányítás
                      context.goNamed(AppRoute.home.name);
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
