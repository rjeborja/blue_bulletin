import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blue_bulletin/login.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    BindingBase.debugZoneErrorsAreFatal = true;
    await Supabase.initialize(
      url: 'https://ctaswgnbdiuulvxxzsek.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0YXN3Z25iZGl1dWx2eHh6c2VrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzEyMjU5MTQsImV4cCI6MjA0NjgwMTkxNH0.e7xURC4lad6XHjsOzI7iXQh6TqfXtjB6k3fKoi92wwQ',
    );
    runApp(const MainApp());
  }, (error, stackTrace) {
    debugPrint('Caught an error: $error\nStack Trace: $stackTrace');
  });
}

final supabase = Supabase.instance.client;
final session = supabase.auth.currentSession;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LogInPage(),
    );
  }
}
