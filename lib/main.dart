import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'models/site_content.dart';
// import 'screens/admin/admin_dashboard.dart';
// import 'screens/admin/admin_login_page.dart';
// import 'screens/admin/admin_projects_page.dart';
import 'screens/inquiry_page.dart';
// import 'screens/projects_page.dart';
// import 'services/content_repository.dart';
import 'widgets/luxury.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Firebase silently in background without blocking app render
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    print('Firebase initialization notice: $e');
    return Firebase.app();
  });

  runApp(const NbApp());
}

class NbApp extends StatelessWidget {
  const NbApp({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultContent = SiteContent.defaults();
    final colors = SiteColors(defaultContent.palette);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => InquiryPage(
            content: defaultContent,
            projectId: 'nb-legacy-tower',
          ),
        ),
        /*
        GoRoute(
          path: '/p/:slug',
          builder: (context, state) => InquiryPage(
            content: defaultContent,
            projectId: 'nb-legacy-tower',
          ),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => _AdminGate(repository: repository),
        ),
        GoRoute(
          path: '/admin/p/:id',
          builder: (context, state) => AdminDashboardPage(projectId: id),
        ),
        */
      ],
    );

    return MaterialApp.router(
      title: 'NB Legacy Tower',
      debugShowCheckedModeBanner: false,
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
      routerConfig: router,
    );
  }
}

/*
class _AdminGate extends StatelessWidget {
  const _AdminGate({required this.repository, this.child});

  final ContentRepository repository;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: repository.authState,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const AdminLoginPage();
        }
        return child ?? AdminProjectsPage(repository: repository);
      },
    );
  }
}
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NbApp();
  }
}

