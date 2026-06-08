import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/flash_page.dart';
import 'services/fastboot_resolver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: '', 
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  try {
    await FastbootResolver.init();
  } catch (e) {
    debugPrint(e.toString());
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTHING OS flash tool',
      
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Ndot-57-Caps',

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0000),
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
          error: Colors.redAccent,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Ndot-57-Caps',
            fontSize: 24, 
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        checkboxTheme: CheckboxThemeData(
          side: const BorderSide(
            color: Colors.grey,
            width: 2.0,
          ),
          
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFF0000); // Ticked: Nothing Red
            }
            return Colors.transparent; // Unticked: Transparent background
          }),

          checkColor: const WidgetStatePropertyAll(Colors.white),
        ),

        listTileTheme: const ListTileThemeData(
          textColor: Colors.black,
        ),
      ),
      home: FlashPage(),
    );
  }
}
