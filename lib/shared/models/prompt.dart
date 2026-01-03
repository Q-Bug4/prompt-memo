import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt.freezed.dart';
part 'prompt.g.dart';

@freezed
class Prompt with _$Prompt {
  const factory Prompt({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? collectionId,
    @Default(0) int usageCount,
    @Default([]) List<String> tags,
  }) = _Prompt;

  factory Prompt.fromJson(Map<String, dynamic> json) => _$PromptFromJson(json);
}
