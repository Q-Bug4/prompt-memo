import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'core/navigation/app_router.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging for development
  _setupLogging();

  // Initialize service locator
  await initServiceLocator();

  runApp(
    const ProviderScope(
      child: PromptMemoApp(),
    ),
  );
}

/// Setup logging configuration
void _setupLogging() {
  // Set global log level to INFO to reduce log noise
  // Use Level.ALL only when detailed debugging is needed
  Logger.root.level = Level.INFO;

  // Set up hierarchical logging
  hierarchicalLoggingEnabled = true;

  // Add a basic log listener that outputs to console
  Logger.root.onRecord.listen((record) {
    // Show all logs including FINE, FINER, FINEST for debugging
    // Change to Level.INFO in production to reduce noise
    _printLog(record);
  });
}

/// Print log record with appropriate formatting
void _printLog(LogRecord record) {
  final levelName = record.level.name.toLowerCase().padRight(7);
  final loggerName = record.loggerName;
  final message = record.message;
  final error = record.error;
  final stack = record.stackTrace;

  final buffer = StringBuffer();
  buffer.write('[$levelName] $loggerName: $message');

  if (error != null) {
    buffer.write('\n  Error: $error');
  }

  if (stack != null) {
    buffer.write('\n  Stack: $stack');
  }

  // Use print to ensure logs appear in console
  print(buffer.toString());
}

class PromptMemoApp extends StatelessWidget {
  const PromptMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prompt Memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 2,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: routerConfig,
    );
  }
}
