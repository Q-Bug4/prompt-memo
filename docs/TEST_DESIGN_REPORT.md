# Prompt Memo - 开发者测试设计

---

## 一、三段式测试说明

| 三段式 | 说明 |
|---------|------|
| **Given** | 给定前提条件，描述测试的初始状态和输入数据 |
| **When** | 当执行某个操作时，描述被测试的行为或触发条件 |
| **Then** | 那么应该发生什么，验证操作后的结果和输出是否符合预期 |

---

## 二、Mock vs Stub

| 类型 | 说明 | 示例 |
|------|------|------|
| **Stub** | 返回预设值，不需要验证调用 | `when(getPromptById('id-1')).thenReturn(existingPrompt)` |
| **Mock** | 可以验证调用，需要配合 `verify()` 使用 | `when(db.insert()).thenAnswer(1)` |

```dart
// Stub 示例（返回预设值）
when(repository.getPromptById('test-id')).thenReturn(testPrompt);

// Mock 示例（可验证调用）
final mockDb = MockDatabaseHelper();
when(mockDb.insert(any, any, any)).thenAnswer((_) async => 1);
verify(mockDb.insert(tableName: 'prompts', values: any));
```

---

## 三、测试文件和目标

| 测试文件 | 测试方法 |
|-----------|-----------|
| lib/features/prompt-management/data/repositories/prompt_repository.dart | createPrompt, updatePrompt, deletePrompt, getPromptById, getAllPrompts |
| lib/features/search/data/repositories/search_repository.dart | searchPrompts, getSearchHistory, saveSearchQuery |
| lib/core/database/database_helper.dart | 数据库初始化、表操作 |

---

## 四、PromptRepository 测试

### 测试目标：验证 PromptRepository 的 CRUD 操作正确调用数据库方法

| 测试组 | 测试用例 |
|--------|----------|
| createPrompt | 正常创建、空标题异常、标签保存为 JSON |
| updatePrompt | 正常更新、更新不存在的 Prompt |
| deletePrompt | 删除 Prompt（含关联的 ResultSample）、删除不存在的 Prompt |
| getPromptById | 获取存在的 Prompt、获取不存在的 Prompt（返回 null） |
| getAllPrompts | 空数据库返回空列表、返回按 updatedAt 降序 |
| createResultSample | 创建结果样本 |
| deleteResultSample | 删除结果样本 |

### 测试用例

```dart
group('PromptRepository.createPrompt', () {
  test('正常创建', () async {
    // Given: 有效标题、内容、标签列表
    // When: 调用 createPrompt
    // Then: 返回的 Prompt 对象包含正确的 id、title、content、tags
  });

  test('空标题抛异常', () async {
    // Given: 调用 createPrompt，title 为空字符串
    // When: 执行创建操作
    // Then: 抛出异常或验证失败
  });

  test('标签保存为 JSON', () async {
    // Given: tags = ['tag1', 'tag2']
    // When: 调用 createPrompt
    // Then: 数据库存储的 tags 为 JSON 字符串 ["tag1","tag2"]
  });
});

group('PromptRepository.updatePrompt', () {
  test('正常更新', () async {
    // Given: 已存在的 Prompt 对象
    // When: 调用 updatePrompt，修改 title/content/tags
    // Then: 数据库更新成功，updatedAt 为新的时间戳
  });

  test('更新不存在的 Prompt', () async {
    // Given: Prompt id 不存在于数据库
    // When: 调用 updatePrompt
    // Then: 不抛异常或返回受影响行数为 0
  });
});

group('PromptRepository.deletePrompt', () {
  test('删除 Prompt', () async {
    // Given: 已存在的 Prompt，关联多个 ResultSample
    // When: 调用 deletePrompt
    // Then: Prompt 从数据库删除、关联的 ResultSample 也被删除、对应文件从文件系统删除
  });

  test('删除不存在的 Prompt', () async {
    // Given: Prompt id 不存在
    // When: 调用 deletePrompt
    // Then: 不抛异常，静默处理
  });
});

group('PromptRepository.getPromptById', () {
  test('获取存在的 Prompt', () async {
    // Given: 数据库中存在指定 id 的 Prompt
    // When: 调用 getPromptById(id)
    // Then: 返回正确的 Prompt 对象，tags 正确解析
  });

  test('获取不存在的 Prompt', () async {
    // Given: 数据库中不存在指定 id
    // When: 调用 getPromptById(不存在的id)
    // Then: 返回 null
  });
});

group('PromptRepository.getAllPrompts', () {
  test('空数据库返回空列表', () async {
    // Given: 数据库为空，没有 Prompt 记录
    // When: 调用 getAllPrompts
    // Then: 返回空列表 []
  });

  test('返回按 updatedAt 降序', () async {
    // Given: 创建多个不同时间的 Prompt
    // When: 调用 getAllPrompts
    // Then: 返回的列表按 updatedAt 降序排列
  });
});
```

---

## 五、SearchRepository 测试

### 测试目标：验证搜索功能正确查询数据库

| 测试组 | 测试用例 |
|--------|----------|
| searchPrompts | 按标题搜索、按内容搜索、按标签搜索、空查询返回所有、日期范围过滤 |
| getSearchHistory | 返回最近搜索、返回最多 20 条记录、按时间降序 |
| saveSearchQuery | 保存新搜索、更新已存在的搜索 |

### 测试用例

```dart
group('SearchRepository.searchPrompts', () {
  test('按标题搜索', () async {
    // Given: 数据库中存在包含 "AI" 的 Prompt
    // When: 调用 searchPrompts(query: "AI")
    // Then: 返回包含 "AI" 的 Prompt 列表
  });

  test('按内容搜索', () async {
    // Given: 数据库中存在包含特定内容的 Prompt
    // When: 调用 searchPrompts(query: "特定内容")
    // Then: 返回匹配的 Prompt
  });

  test('按标签搜索', () async {
    // Given: 数据库中存在标签为 "work" 的 Prompt
    // When: 调用 searchPrompts(query: "work")
    // Then: 返回所有带 "work" 标签的 Prompt
  });

  test('空查询返回所有', () async {
    // Given: 数据库中有多个 Prompt
    // When: 调用 searchPrompts(query: "")
    // Then: 返回所有 Prompt（等同于 getAllPrompts）
  });

  test('日期范围过滤', () async {
    // Given: 数据库中存在不同时间的 Prompt
    // When: 调用 searchPrompts(startDate: yesterday, endDate: today)
    // Then: 只返回该时间范围内的 Prompt
  });
});

group('SearchRepository.getSearchHistory', () {
  test('返回最近搜索', () async {
    // Given: 有多次搜索记录
    // When: 调用 getSearchHistory
    // Then: 返回最多 20 条记录，按时间降序
  });

  test('清除历史', () async {
    // Given: 存在搜索历史记录
    // When: 调用 clearSearchHistory
    // Then: 所有历史记录被删除
  });
});
```

---

## 六、本地验证命令

```bash
# 运行所有单元测试
flutter test

# 测试覆盖率
flutter test --coverage

# 分析代码
flutter analyze

# 构建 Linux 版本进行测试
flutter build linux --release
./build/linux/x64/release/bundle/prompt_memo
```
