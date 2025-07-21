
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/loading_overlay.dart';

import '../routing/app_router.dart';
import '../viewmodels/flat_selector_viewmodel.dart';
import '../viewmodels/lease_contract_viewmodel.dart';
import '../viewmodels/theme_provider.dart';
import '../widgets/signature_page.dart';

class LeaseContractFormPage extends ConsumerWidget {
  const LeaseContractFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFlat = ref.watch(selectedFlatProvider);
    if (selectedFlat == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakás")),
      );
    }
    final vm = ref.watch(leaseContractViewModelProvider(selectedFlat.id as String));
    final vmNotifier = ref.read(leaseContractViewModelProvider(selectedFlat.id as String).notifier);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  60,
                  MediaQuery.of(context).padding.top,
                  16,
                  0,
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Bérleti szerződés készítés',
                    style: TextStyle(
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Albérlő neve'),
                onChanged: vmNotifier.setTenantName,
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SignaturePage(
                        onDone: (signatureImage) {
                          vmNotifier.setSignature(signatureImage);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Aláírás hozzáadása'),
              ),

              if (vm.signature != null) ...[
                const SizedBox(height: 10),
                const Text('Aláírás hozzáadva:'),
                SizedBox(height: 100, child: Image.memory(vm.signature!)),
              ],

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  await vmNotifier.createLeaseContractAndUpload();
                  if (!vm.isLoading) {
                    CustomSnackBar.success(context, "Bérleti szerződés feltöltve!");
                    context.goNamed(
                      AppRoute.documents.name,
                      pathParameters: {"flatId": selectedFlat.id as String},
                    );
                  }
                },
                child: const Text('Mentés és feltöltés'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
