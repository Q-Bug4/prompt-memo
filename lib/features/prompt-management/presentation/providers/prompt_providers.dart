import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_memo/shared/models/prompt.dart';
import 'package:prompt_memo/shared/models/result_sample.dart';
import 'package:prompt_memo/features/prompt-management/data/repositories/prompt_repository.dart';

/// Provider for prompt repository
final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository();
});

/// Provider for all prompts
final promptsProvider = FutureProvider<List<Prompt>>((ref) async {
  final repository = ref.watch(promptRepositoryProvider);
  return repository.getAllPrompts();
});

/// Provider for prompts in a collection
final promptsByCollectionProvider =
    FutureProvider.family<List<Prompt>, String>((ref, collectionId) async {
      final repository = ref.watch(promptRepositoryProvider);
      return repository.getPromptsByCollection(collectionId);
    });

/// Provider for a single prompt
final promptProvider =
    FutureProvider.family<Prompt?, String>((ref, id) async {
      final repository = ref.watch(promptRepositoryProvider);
      return repository.getPromptById(id);
    });

/// Provider for result samples
final resultSamplesProvider =
    FutureProvider.family<List<ResultSample>, String>((ref, promptId) async {
      final repository = ref.watch(promptRepositoryProvider);
      return repository.getResultSamples(promptId);
    });

/// State provider for prompt list operations
class PromptListNotifier extends StateNotifier<List<Prompt>> {
  final PromptRepository _repository;

  PromptListNotifier(this._repository) : super([]) {
    loadPrompts();
  }

  Future<void> loadPrompts() async {
    final prompts = await _repository.getAllPrompts();
    state = prompts;
  }

  Future<void> deletePrompt(String id) async {
    await _repository.deletePrompt(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<ResultSample?> addResultSample(String promptId, String filePath, String fileName, int fileSize, String fileType) async {
    final result = await _repository.createResultSampleSimple(
      promptId: promptId,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      fileType: fileType,
    );
    return result;
  }
}

/// Provider for prompt list operations
final promptListNotifierProvider =
    StateNotifierProvider<PromptListNotifier, List<Prompt>>((ref) {
      final repository = ref.watch(promptRepositoryProvider);
      return PromptListNotifier(repository);
    });
