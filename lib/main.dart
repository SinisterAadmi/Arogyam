import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_colors.dart';
import 'features/patient/presentation/pages/patient_home/patient_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ArogyamApp());
}

class ArogyamApp extends StatelessWidget {
  const ArogyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogyam / HealthQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal,
          surface: AppColors.card,
        ),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const PatientHomePage(),
    );
  }
}
