import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/lease_contract_viewmodel.dart';

class LeaseContractFormPage extends ConsumerWidget {
  const LeaseContractFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(leaseContractViewModelProvider(""));
    final vmNotifier = ref.read(leaseContractViewModelProvider("").notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bérleti szerződés készítése')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Albérlő neve'),
              onChanged: vmNotifier.setTenantName,
            ),
            const SizedBox(height: 16),
            // Ide tehetsz dátumválasztót, számbevitelt stb.
            ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                await vmNotifier.createLeaseContractAndUpload();
                if (!vm.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bérleti szerződés feltöltve')),
                  );
                  context.pop();
                }
              },
              child: vm.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Mentés és feltöltés'),
            ),
          ],
        ),
      ),
    );
  }
}
