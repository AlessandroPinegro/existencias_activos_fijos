import 'package:flutter/material.dart';
import 'core/storage/secure_storage_service.dart';
import 'presentation/screens/home_mobile_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SecureStorageService.getToken();

  runApp(CoreFlowMobileApp(isLoggedIn: token != null && token.isNotEmpty));
}

class CoreFlowMobileApp extends StatelessWidget {
  final bool isLoggedIn;

  const CoreFlowMobileApp({super.key, required this.isLoggedIn});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoreFlow Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
        ),
      ),
      home: isLoggedIn ? const HomeMobileScreen() : const LoginScreen(),
    );
  }
}
