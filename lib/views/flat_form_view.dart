import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/theme/theme.dart';
import 'package:rentmate/viewmodels/auth_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/flat_list_provider.dart';
import '../viewmodels/flat_viewmodel.dart'; // vagy ahová tetted a FlatViewmodel-t

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
    final flatState = ref.read(flatViewModelProvider);
    final flatVM = ref.read(flatViewModelProvider.notifier);
    final asyncUser = ref.read(currentUserProvider);
    final user = asyncUser.asData?.value;
    return Scaffold(
      extendBodyBehindAppBar: true, // hogy az appbar rárajzoljon a body-ra
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
                    'Lakás hozzáadása',
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
              // Ha kell vissza gomb:
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

      body:
          flatState.isLoading || user == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Cím'),
                        validator:
                            RequiredValidator(
                              errorText: 'A cím megadása kötelező!',
                            ).call,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Ár'),
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
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<
                              Color?
                          >((Set<WidgetState> states) {
                            return lightMode.primaryColor; // alap háttérszín
                          }),
                        ),
                        onPressed: () async {
                          showModalBottomSheet(
                            context: context,
                            builder:
                                (context) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.photo_library,
                                        ),
                                        title: const Text('Galéria'),
                                        onTap: () async {
                                          Navigator.of(context).pop();
                                          final images =
                                              await flatVM.pickImages();
                                          if (images != null) {
                                            final filtered =
                                                images.where((file) {
                                                  final ext =
                                                      file.path.toLowerCase();
                                                  return ext.endsWith('.jpg') ||
                                                      ext.endsWith('.jpeg') ||
                                                      ext.endsWith('.png');
                                                }).toList();

                                            if (filtered.length +
                                                    selectedImages.length >
                                                6) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                CustomSnackBar.error(
                                                  "Legfeljebb 6 képet tölthetsz fel.",
                                                ),
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
                                          final photo =
                                              await flatVM.takePhoto();
                                          if (photo != null) {
                                            final ext =
                                                photo.path.toLowerCase();
                                            if (!(ext.endsWith('.jpg') ||
                                                ext.endsWith('.jpeg') ||
                                                ext.endsWith('.png'))) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                CustomSnackBar.error(
                                                  "Csak JPG vagy PNG képek engedélyezettek.",
                                                ),
                                              );
                                              return;
                                            }

                                            if (selectedImages.length >= 6) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                CustomSnackBar.error(
                                                  "Legfeljebb 6 képet tölthetsz fel.",
                                                ),
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
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<
                            Color?
                          >((Set<WidgetState> states) {
                            return lightMode.primaryColor; // alap háttérszín
                          }),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (selectedImages.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CustomSnackBar.error(
                                  "Legalább egy képet válassz!",
                                ),
                              );
                              return;
                            }

                            await flatVM.save(
                              context,
                              address: _addressController.text.trim(),
                              price: _priceController.text.trim(),
                              images: selectedImages,
                              flatStatus: FlatStatus.active,
                              landlord: user,
                            );
                            ref.read(flatListProvider.notifier).refresh();
                          }
                        },
                        child: const Text('Mentés'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
