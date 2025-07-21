import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../routing/app_router.dart';
import '../viewmodels/flat_selector_viewmodel.dart';
import '../viewmodels/lease_contract_viewmodel.dart';
import '../viewmodels/theme_provider.dart';
import '../widgets/signature_pad.dart';

class LeaseContractFormPage extends ConsumerStatefulWidget {
  const LeaseContractFormPage({super.key});

  @override
  ConsumerState<LeaseContractFormPage> createState() =>
      _LeaseContractFormPageState();
}

class _LeaseContractFormPageState extends ConsumerState<LeaseContractFormPage> {
  int _currentStep = 0;
  final List<TextEditingController> nameControllers = [];
  final List<Uint8List?> tenantSignatures = [];
  Uint8List? landlordSignature;

  // Szerződés adatokhoz controller-ek
  DateTime? leaseStart;
  DateTime? leaseEnd;
  bool indefiniteLease = false;
  final TextEditingController depositController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController noticePeriodController = TextEditingController();
  final TextEditingController otherAgreementsController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.watch(selectedFlatProvider);
    if (selectedFlat == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakás")),
      );
    }

    final tenants = selectedFlat.tenants;
    if (tenants == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakásban albérlő")),
      );
    }

    final vm = ref.watch(
      leaseContractViewModelProvider(selectedFlat.id as String),
    );
    final vmNotifier = ref.read(
      leaseContractViewModelProvider(selectedFlat.id as String).notifier,
    );

    // Ha még nincs controller a nevekre, hozzuk létre
    while (nameControllers.length < tenants.length) {
      nameControllers.add(
        TextEditingController(text: tenants[nameControllers.length].name),
      );
      tenantSignatures.add(null);
    }

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
                    'Bérleti szerződés létrehozása',
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
                  onPressed: () => context.goNamed(AppRoute.home.name),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: vm.isLoading,
        child: Stepper(
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final isLastStep = _currentStep == (tenants.length + 2) - 1;
            return Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLastStep ? 'Mentés' : 'Tovább'),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Vissza'),
                  ),
              ],
            );
          },
          currentStep: _currentStep,
          onStepContinue: () async {
            final totalSteps = tenants.length + 2;

            if (_currentStep == 0) {
              // 0. lépés: szerződés adatok validálása
              if (leaseStart == null ||
                  (!indefiniteLease && leaseEnd == null)) {
                CustomSnackBar.error(
                  context,
                  "Kérlek add meg a szerződés dátumait!",
                );
                return;
              }
              setState(() => _currentStep++);
              return;
            }

            if (_currentStep > 0 && _currentStep <= tenants.length) {
              // Albérlő(k) aláírása
              final tenantIndex =
                  _currentStep -
                  1; // mert albérlők az 1..tenants.length indexek
              if (tenantSignatures[tenantIndex] == null) {
                CustomSnackBar.error(
                  context,
                  "Kérlek add meg az albérlő aláírását!",
                );
                return;
              }
              setState(() => _currentStep++);
              return;
            }

            if (_currentStep == tenants.length + 1) {
              // Főbérlő aláírása
              if (landlordSignature == null) {
                CustomSnackBar.error(
                  context,
                  "Kérlek add meg a főbérlő aláírását!",
                );
                return;
              }

              // Mentés - mivel ez az utolsó lépés, itt végrehajtjuk a mentést
              final collectedTenants = List.generate(tenants.length, (i) {
                return {
                  'name': nameControllers[i].text,
                  'signature': tenantSignatures[i],
                };
              });

              await vmNotifier.setMultipleSignatures(
                collected: collectedTenants,
                leaseStart: leaseStart!,
                leaseEnd: indefiniteLease ? null : leaseEnd!,
                deposit: depositController.text,
                rent: rentController.text,
                noticePeriod: noticePeriodController.text,
                otherAgreements: otherAgreementsController.text,
                landlordSignature: landlordSignature!,
              );

              if (!vm.isLoading) {
                CustomSnackBar.success(context, "Bérleti szerződés feltöltve!");
                context.goNamed(
                  AppRoute.documents.name,
                  pathParameters: {"flatId": selectedFlat.id as String},
                );
              }

              // Nem lépünk tovább, mert utolsó lépés volt
              return;
            }

            // Biztonsági feltétel: nem lépünk túl a lépések számán
            if (_currentStep >= totalSteps) {
              return;
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              isActive: _currentStep >= 0,
              state: _currentStep == 0
                  ? StepState.editing
                  : (_currentStep > 0
                  ? (isLeaseDataComplete() ? StepState.complete : StepState.error)
                  : StepState.indexed),
              title: const Text('Szerződés adatok'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: leaseStart ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => leaseStart = picked);
                      }
                    },
                    child: Text(
                      leaseStart == null
                          ? "Bérleti időszak kezdete kiválasztása"
                          : "Kezdő dátum: ${leaseStart!.toLocal().toString().split(' ')[0]}",
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: indefiniteLease,
                        onChanged: (v) => setState(() {
                          indefiniteLease = v ?? false;
                          if (indefiniteLease) leaseEnd = null;
                        }),
                      ),
                      const Text('Határozatlan időre szól a szerződés'),
                    ],
                  ),
                  if (!indefiniteLease)
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: leaseEnd ?? (leaseStart ?? DateTime.now()),
                          firstDate: leaseStart ?? DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => leaseEnd = picked);
                        }
                      },
                      child: Text(
                        leaseEnd == null
                            ? "Bérleti időszak vége kiválasztása"
                            : "Lejárati dátum: ${leaseEnd!.toLocal().toString().split(' ')[0]}",
                      ),
                    ),
                  TextField(
                    controller: depositController,
                    decoration: const InputDecoration(
                      labelText: 'Kaució összege (Ft)',
                      hintText: 'Pl. 100000',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noticePeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Felmondási idő (napokban)',
                      hintText: 'Pl. 30',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otherAgreementsController,
                    decoration: const InputDecoration(
                      labelText: 'Egyéb megállapodások',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Albérlők lépései (egy-egy lépés minden albérlőnek)
            for (var i = 0; i < tenants.length; i++)
              Step(
                state: _currentStep == i + 1
                    ? StepState.editing
                    : (_currentStep > i + 1
                    ? (isTenantSigned(i) ? StepState.complete : StepState.error)
                    : StepState.indexed),
                isActive: _currentStep >= i + 1,
                title: Text('${tenants[i].name} aláírása'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SignaturePad(
                      onDone: (signatureImage) {
                        setState(() {
                          tenantSignatures[i] = signatureImage;
                        });
                        CustomSnackBar.success(context, 'Aláírás mentve!');
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Főbérlő aláírása lépés
            Step(
              state: _currentStep == tenants.length + 1
                  ? StepState.editing
                  : (_currentStep > tenants.length + 1
                  ? (isLandlordSigned() ? StepState.complete : StepState.error)
                  : StepState.indexed),
              isActive: _currentStep >= tenants.length + 1,
              title: const Text('Főbérlő aláírása'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kérjük, add meg a főbérlő aláírását',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SignaturePad(
                    onDone: (signatureImage) {
                      setState(() {
                        landlordSignature = signatureImage;
                      });
                      CustomSnackBar.success(context, 'Aláírás mentve!');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    depositController.dispose();
    rentController.dispose();
    noticePeriodController.dispose();
    otherAgreementsController.dispose();
    super.dispose();
  }


// Szerződés adatok helyessége
  bool isLeaseDataComplete() {
    if (leaseStart == null) return false;
    if (!indefiniteLease && leaseEnd == null) return false;
    // Egyéb mezők ellenőrzése, ha szükséges (pl. kaució szám)
    return true;
  }

// Albérlő aláírása adott indexen
  bool isTenantSigned(int index) {
    return tenantSignatures.length > index && tenantSignatures[index] != null;
  }

// Főbérlő aláírása
  bool isLandlordSigned() {
    return landlordSignature != null;
  }

  StepState getStepState(int stepIndex, bool isComplete, bool hasError) {
    if (_currentStep == stepIndex) {
      if (hasError) {
        return StepState.error;     // Hibás az aktuális lépés
      }
      return StepState.editing;     // Aktuális lépés rendben
    } else if (stepIndex < _currentStep && isComplete) {
      return StepState.complete;   // Befejezett lépés
    } else if (stepIndex < _currentStep && hasError) {
      return StepState.error;      // Hibás, de már nem aktuális lépés
    } else {
      return StepState.indexed;    // Még nem elért lépés
    }
  }
}
