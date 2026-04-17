import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/core/router_config.dart';
import 'src/core/theme/app_theme.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:washfamily/firebase_options.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        mapsImplementation.useAndroidViewSurface = true;
        await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.legacy);
      }
    } catch (e) {
      debugPrint('Map renderer init failed: $e');
    }
  }

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr', null); // Locale française pour intl
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WashFamily',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
