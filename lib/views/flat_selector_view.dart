import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/flat_selector_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class ApartmentSelectorScreen extends ConsumerStatefulWidget {
  const ApartmentSelectorScreen({super.key});

  @override
  ConsumerState<ApartmentSelectorScreen> createState() =>
      _ApartmentSelectorScreenState();
}

class _ApartmentSelectorScreenState
    extends ConsumerState<ApartmentSelectorScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;
    final flatsState = ref.watch(
      flatSelectorViewModelProvider(payload?.userId),
    );

    print(flatsState.value?.length);

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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top,
                  16,
                  0,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Lakás választó',
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
            ],
          ),
        ),
      ),
      body: flatsState.when(
        data: (flats) {
          print("UI flats count: ${flats.length}");
          if (flats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Még nincs lakásod a rendszerben.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Lakás hozzáadása'),
                    onPressed: () {
                      context.goNamed(AppRoute.createFlat.name);
                    },
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(flat.address),
                  subtitle: Text('${flat.price} Ft / hó'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ref.read(selectedFlatProvider.notifier).state = flat;
                    context.goNamed(AppRoute.home.name);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hiba történt: $err')),
      ),
    );
  }
}
