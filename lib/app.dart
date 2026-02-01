import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/command_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';

class MonarchCommandApp extends StatelessWidget {
  const MonarchCommandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Monarch Command',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const CommandScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
