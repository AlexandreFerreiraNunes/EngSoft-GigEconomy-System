import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'auth/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const GigApp());
}

class GigApp extends StatelessWidget {
  const GigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GigFinance',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashPage(),
    );
  }
}
