import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/theme.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isDarkMode = ref.watch(
      themeModeProvider,
    ); // Riverpod state provider (lásd lentebb)
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'RentMate',
      theme: realEstateTheme,
      darkTheme: realEstateDarkTheme,
      themeMode: isDarkMode,
      routerConfig: router,
    );
  }
}
