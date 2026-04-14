import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'utils/shared_prefs.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background handler is already initialized in notification_service.dart via its imports
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await SharedPrefs.init();
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ConVenZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
