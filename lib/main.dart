import 'package:flutter/material.dart';
import 'package:rentmate/theme/theme.dart';
import 'package:rentmate/views/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(    url: 'https://zxjbzmbucrrhpqkpusjb.supabase.co',    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4amJ6bWJ1Y3JyaHBxa3B1c2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyMzk0MzUsImV4cCI6MjA2MzgxNTQzNX0.0pvOd0CHoT54Q77FdE0gBW9g0apTJ3wkL5toEbsGoIs',  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RentMate',
      theme: lightMode,
      home: const WelcomeScreen(),
    );
  }
}
