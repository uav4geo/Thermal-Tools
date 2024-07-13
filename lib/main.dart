import 'package:dji_thermal_tools/pages/home_page.dart';
import 'package:dji_thermal_tools/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final theme = ref.watch(themeProvider);

        return MaterialApp(
          title: 'Thermal Tools',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: theme.themeData,
          //home: const HomePage(title: 'Thermal Tools by UAV4GEO'),
          home: const Home(),
        );
      },
    );
  }
}
