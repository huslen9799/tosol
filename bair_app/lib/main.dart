import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/app_store.dart';
import 'widgets/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BairApp());
}

class BairApp extends StatefulWidget {
  final AppStore? store;
  const BairApp({super.key, this.store});
  @override
  State<BairApp> createState() => _BairAppState();
}

class _BairAppState extends State<BairApp> {
  late final AppStore store;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? AppStore();
    if (store.restoring) store.restore();
  }

  @override
  void dispose() {
    if (widget.store == null) {
      store.api.client.close();
      store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    store: store,
    child: AnimatedBuilder(
      animation: appThemeMode,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Өргөө',
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: appThemeMode.value,
        home: AnimatedBuilder(
          animation: store,
          builder: (_, child) => store.restoring
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : const MainScreen(),
        ),
      ),
    ),
  );
}
