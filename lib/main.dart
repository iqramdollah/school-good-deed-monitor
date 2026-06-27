import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sriwaap/app_router.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/firebase_options.dart';

// import 'firebase_options.dart'; // Uncomment after running flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Uncomment after flutterfire configure
  );
  runApp(const ProviderScope(child: TurquoiseApp()));
}

class TurquoiseApp extends ConsumerWidget {
  const TurquoiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Turquoise',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
