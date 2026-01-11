import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/collection_repository.dart';
import 'package:prompt_memo/shared/models/collection.dart';

/// Provider for collection repository
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

/// Provider for all collections
final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.getAllCollections();
});

/// Provider for a single collection by ID
final collectionProvider = FutureProvider.family<Collection?, String>((ref, id) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.getCollectionById(id);
});

/// State notifier for collection list operations
class CollectionListNotifier extends StateNotifier<List<Collection>> {
  final CollectionRepository _repository;

  CollectionListNotifier(this._repository) : super([]) {
    loadCollections();
  }

  /// Load all collections
  Future<void> loadCollections() async {
    final collections = await _repository.getAllCollections();
    state = collections;
  }

  /// Delete a collection
  Future<void> deleteCollection(String id) async {
    await _repository.deleteCollection(id);
    state = state.where((c) => c.id != id).toList();
  }
}

/// Provider for collection list operations
final collectionListProvider = StateNotifierProvider<CollectionListNotifier, List<Collection>>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return CollectionListNotifier(repository);
});
