import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'models/site_content.dart';
import 'screens/admin_page.dart';
import 'screens/inquiry_page.dart';
import 'widgets/luxury.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase silently in background without blocking app render
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    debugPrint('Firebase initialization notice: $e');
    return Firebase.app();
  });

  runApp(const NbApp());
}

final _defaultContent = SiteContent.defaults();

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => InquiryPage(
        content: _defaultContent,
        projectId: 'nb-legacy-tower',
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
  ],
  errorBuilder: (context, state) {
    if (state.uri.path.contains('admin')) {
      return const AdminPage();
    }
    return InquiryPage(
      content: _defaultContent,
      projectId: 'nb-legacy-tower',
    );
  },
);

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class NbApp extends StatelessWidget {
  const NbApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SiteColors(_defaultContent.palette);

    return MaterialApp.router(
      title: 'NB Legacy Tower',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: colors.background,
        colorScheme: ColorScheme.light(
          primary: colors.brass,
          secondary: colors.blue,
          surface: colors.surface,
          onPrimary: colors.onDark,
          onSecondary: colors.onDark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colors.black,
          foregroundColor: colors.onDark,
        ),
      ),
      routerConfig: _router,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbApp();
  }
}

