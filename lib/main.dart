import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://abrmnhlxwkddvgfperjm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFicm1uaGx4d2tkZHZnZnBlcmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMjIzMTgsImV4cCI6MjA5MTg5ODMxOH0.21nGi-hW7vr4kCp0yVL_TgpBRZS5fwMOdrV2Z9sf1MQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Health Record',
      home: Scaffold(
        appBar: AppBar(title: const Text('Emergency Health Record')),
        body: const Center(child: Text('Connected to Supabase')),
      ),
    );
  }
}