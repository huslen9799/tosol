import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/app_store.dart';

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
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Өргөө',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF285747),
          primary: const Color(0xFF285747),
          secondary: const Color(0xFF285747),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF172D29),
          onSurfaceVariant: const Color(0xFF62736D),
          primaryContainer: const Color(0xFFEDF4EE),
          onPrimaryContainer: const Color(0xFF103F36),
          secondaryContainer: const Color(0xFFEDF4EE),
          onSecondaryContainer: const Color(0xFF285747),
          error: const Color(0xFFEF4444),
          outline: const Color(0xFFDFE6DC),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7F3),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF285747),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7F3),
          foregroundColor: Color(0xFF172D29),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF172D29),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFEDF4EE),
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF285747)
                  : const Color(0xFF93A49C),
              size: 24,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF285747)
                  : const Color(0xFF93A49C),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF285747)
                  : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF62736D),
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(color: Color(0xFFDFE6DC)),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDFE6DC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFE6DC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFE6DC)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: store,
        builder: (_, child) => store.restoring
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : const MainScreen(),
      ),
    ),
  );
}
