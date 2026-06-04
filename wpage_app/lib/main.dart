import 'package:flutter/material.dart';

import 'models/page_model.dart';
import 'screens/generate_wpage_screen.dart';
import 'screens/page_preview_screen.dart';
import 'screens/page_review_screen.dart';
import 'screens/publish_success_screen.dart';
import 'screens/purpose_screen.dart';

void main() {
  runApp(const WPageApp());
}

class WPageApp extends StatelessWidget {
  const WPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const PurposeScreen());
          case '/generate-wpage':
            return MaterialPageRoute(
              builder: (_) => GenerateWPageScreen(
                purpose: settings.arguments as String?,
              ),
            );
          case '/generate':
            return MaterialPageRoute(
              builder: (_) => GenerateWPageScreen(
                purpose: settings.arguments as String?,
              ),
            );
          case '/review':
            return MaterialPageRoute(
              builder: (_) => PageReviewScreen(
                generateResult: settings.arguments as GeneratePageResult,
              ),
            );
          case '/preview':
            return MaterialPageRoute(
              builder: (_) => PagePreviewScreen(
                page: settings.arguments as PageModel,
              ),
            );
          case '/success':
            return MaterialPageRoute(
              builder: (_) => PublishSuccessScreen(
                result: settings.arguments as PublishResult,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const PurposeScreen());
        }
      },
    );
  }
}
