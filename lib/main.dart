import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => SpecialtyProvider()),
        // Ajoutez d'autres providers ici
      ],
      child: MaterialApp(
        title: 'DoctorPoint',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}