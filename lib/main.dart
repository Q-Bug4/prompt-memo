import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'core/navigation/app_router.dart';
import 'core/service_locator.dart';
import 'package:prompt_memo/features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging for development
  _setupLogging();

  // Initialize service locator
  await initServiceLocator();

  // Initialize settings provider to load saved preferences
  final container = ProviderContainer();
  container.read(settingsProvider.notifier);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PromptMemoApp(),
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

class PromptMemoApp extends ConsumerWidget {
  const PromptMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Prompt Memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(elevation: 2),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(elevation: 2),
      ),
      themeMode: _convertAppThemeMode(settings.themeMode),
      routerConfig: routerConfig,
    );
  }

  ThemeMode _convertAppThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
