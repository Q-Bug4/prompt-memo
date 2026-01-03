// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prompt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Prompt _$PromptFromJson(Map<String, dynamic> json) {
  return _Prompt.fromJson(json);
}

/// @nodoc
mixin _$Prompt {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get collectionId => throw _privateConstructorUsedError;
  int get usageCount => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this Prompt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Prompt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromptCopyWith<Prompt> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromptCopyWith<$Res> {
  factory $PromptCopyWith(Prompt value, $Res Function(Prompt) then) =
      _$PromptCopyWithImpl<$Res, Prompt>;
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    DateTime createdAt,
    DateTime updatedAt,
    String? collectionId,
    int usageCount,
    List<String> tags,
  });
}

/// @nodoc
class _$PromptCopyWithImpl<$Res, $Val extends Prompt>
    implements $PromptCopyWith<$Res> {
  _$PromptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Prompt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? collectionId = freezed,
    Object? usageCount = null,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            collectionId:
                freezed == collectionId
                    ? _value.collectionId
                    : collectionId // ignore: cast_nullable_to_non_nullable
                        as String?,
            usageCount:
                null == usageCount
                    ? _value.usageCount
                    : usageCount // ignore: cast_nullable_to_non_nullable
                        as int,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PromptImplCopyWith<$Res> implements $PromptCopyWith<$Res> {
  factory _$$PromptImplCopyWith(
    _$PromptImpl value,
    $Res Function(_$PromptImpl) then,
  ) = __$$PromptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    DateTime createdAt,
    DateTime updatedAt,
    String? collectionId,
    int usageCount,
    List<String> tags,
  });
}

/// @nodoc
class __$$PromptImplCopyWithImpl<$Res>
    extends _$PromptCopyWithImpl<$Res, _$PromptImpl>
    implements _$$PromptImplCopyWith<$Res> {
  __$$PromptImplCopyWithImpl(
    _$PromptImpl _value,
    $Res Function(_$PromptImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Prompt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? collectionId = freezed,
    Object? usageCount = null,
    Object? tags = null,
  }) {
    return _then(
      _$PromptImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        collectionId:
            freezed == collectionId
                ? _value.collectionId
                : collectionId // ignore: cast_nullable_to_non_nullable
                    as String?,
        usageCount:
            null == usageCount
                ? _value.usageCount
                : usageCount // ignore: cast_nullable_to_non_nullable
                    as int,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PromptImpl implements _Prompt {
  const _$PromptImpl({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.collectionId,
    this.usageCount = 0,
    final List<String> tags = const [],
  }) : _tags = tags;

  factory _$PromptImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromptImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? collectionId;
  @override
  @JsonKey()
  final int usageCount;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'Prompt(id: $id, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, collectionId: $collectionId, usageCount: $usageCount, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.collectionId, collectionId) ||
                other.collectionId == collectionId) &&
            (identical(other.usageCount, usageCount) ||
                other.usageCount == usageCount) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    content,
    createdAt,
    updatedAt,
    collectionId,
    usageCount,
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of Prompt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromptImplCopyWith<_$PromptImpl> get copyWith =>
      __$$PromptImplCopyWithImpl<_$PromptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromptImplToJson(this);
  }
}

abstract class _Prompt implements Prompt {
  const factory _Prompt({
    required final String id,
    required final String title,
    required final String content,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? collectionId,
    final int usageCount,
    final List<String> tags,
  }) = _$PromptImpl;

  factory _Prompt.fromJson(Map<String, dynamic> json) = _$PromptImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get collectionId;
  @override
  int get usageCount;
  @override
  List<String> get tags;

  /// Create a copy of Prompt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromptImplCopyWith<_$PromptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
