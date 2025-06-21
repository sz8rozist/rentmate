import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/theme.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(    url: 'https://zxjbzmbucrrhpqkpusjb.supabase.co',    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4amJ6bWJ1Y3JyaHBxa3B1c2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyMzk0MzUsImV4cCI6MjA2MzgxNTQzNX0.0pvOd0CHoT54Q77FdE0gBW9g0apTJ3wkL5toEbsGoIs',  );
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isDarkMode = ref.watch(themeModeProvider); // Riverpod state provider (lásd lentebb)
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
