import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // auto-generated
import 'screens/globe_screen.dart';
import 'providers/crypto_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/globe_provider.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseService.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const GlobeCryptoApp());
}

class GlobeCryptoApp extends StatelessWidget {
  const GlobeCryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure providers are above MaterialApp so any descendant (including
    // the home screen) can find them via context.read/watch.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GlobeProvider()),
        ChangeNotifierProvider(create: (_) => CryptoProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
      ],
      child: MaterialApp(
        title: 'CryptoGlobe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E27),
          primaryColor: const Color(0xFF6C5CE7),
        ),
        home: const GlobeScreen(),
      ),
    );
  }
}


 


