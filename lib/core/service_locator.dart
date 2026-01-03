import 'package:get_it/get_it.dart';
import 'package:prompt_memo/core/database/database_helper.dart';
import 'package:prompt_memo/core/storage/file_storage_interface.dart';
import 'package:prompt_memo/core/storage/filesystem_storage.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/prompt_repository.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/collection_repository.dart';
import 'package:prompt_memo/features/search/data/repositories/search_repository.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Initializes all services and repositories
Future<void> initServiceLocator() async {
  // Core services
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());
  getIt.registerSingleton<FileStorageInterface>(FilesystemStorage());

  // Repositories
  getIt.registerFactory<PromptRepository>(() => PromptRepository());
  getIt.registerFactory<CollectionRepository>(() => CollectionRepository());
  getIt.registerFactory<SearchRepository>(() => SearchRepository());
}

/// Resets service locator (for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
