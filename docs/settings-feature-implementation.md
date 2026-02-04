# 设置功能实现说明 (v1.1.0)

## 已实现的功能

### 1. 主题切换功能
- **文件**: `lib/main.dart`
- **功能**:
  - 支持系统默认、浅色、深色三种主题模式
  - 主题选择自动保存到SharedPreferences
  - 应用启动时自动加载上次选择的主题

### 2. 数据导入/导出功能
- **文件**:
  - `lib/features/settings/domain/services/data_export_service.dart` - 数据导出服务
  - `lib/features/settings/presentation/screens/data_management_screen.dart` - 数据管理界面
- **功能**:
  - **导出数据**:
    - 导出所有prompts、collections和samples为JSON格式
    - 包含版本信息和导出时间戳
    - 格式化输出便于阅读
  - **导入数据**:
    - 从JSON文件导入数据
    - 智能合并：已存在的collection和prompt自动跳过
    - 自动映射collection ID和prompt ID
    - 验证文件是否存在

### 3. 缓存管理功能
- **文件**:
  - `lib/features/settings/domain/services/cache_service.dart` - 缓存服务
  - `lib/features/settings/presentation/screens/data_management_screen.dart` - 数据管理界面
- **功能**:
  - **获取缓存大小**: 计算results目录和数据库文件的占用空间
    - Linux/macOS/Windows: `getApplicationSupportDirectory()/com.promptmemo.prompt_memo/results/`
    - 数据库: `getApplicationSupportDirectory()/com.promptmemo.prompt_memo/prompt_memo.db`
  - **清除缓存**: 删除results目录中的所有文件（保留目录结构）
  - **删除所有数据**: 删除数据库和results目录
  - **存储信息**: 显示详细的存储使用情况
    - 数据库大小
    - 图片数量和大小
    - 视频数量和大小
    - 文本文件数量和大小
    - 缓存大小（results目录）
    - 总计大小

### 4. 版本更新功能
- **文件**: 
  - `lib/features/settings/presentation/screens/update_screen.dart`
  - `lib/core/config/app_info.dart` - 统一配置
- **功能**:
  - 从统一配置获取版本信息
  - 从统一配置获取GitHub API地址（Q-Bug4/prompt-memo）
  - 比较当前版本和最新版本
  - 显示更新日志
  - 点击下载链接在浏览器中打开下载页面
  - 显示历史版本信息
  - 错误处理和加载状态显示

### 5. 关于页面
- **文件**: 
  - `lib/features/settings/presentation/screens/about_screen.dart`
  - `lib/core/config/app_info.dart` - 统一配置
- **功能**:
  - 从统一配置获取版本信息（v1.1.0）
  - 从统一配置获取GitHub链接
    - GitHub Repository: https://github.com/Q-Bug4/prompt-memo
    - GitHub Issues: https://github.com/Q-Bug4/prompt-memo/issues
    - GitHub Wiki: https://github.com/Q-Bug4/prompt-memo/wiki
    - MIT许可证信息
    - 点击链接在浏览器中打开
  - 显示应用描述和新功能

### 6. 统一配置
- **文件**: `lib/core/config/app_info.dart`
- **功能**:
  - 集中管理所有应用信息
  - 版本号（v1.1.0）
  - GitHub仓库信息
  - 许可证信息
  - 开发者信息
  - 所有页面使用同一数据源

## 使用方法

### 访问设置
1. 打开应用
2. 点击主页右上角的设置图标
3. 进入设置页面

### 主题切换
1. 进入设置 → Appearance
2. 点击"Theme"选项
3. 选择"System Default"、"Light"或"Dark"
4. 主题立即生效

### 数据导出
1. 进入设置 → Data Management
2. 点击"Export Data"
3. 选择保存目录
4. 等待导出完成
5. 查看导出成功提示

### 数据导入
1. 进入设置 → Data Management
2. 点击"Import Data"
3. 选择之前导出的JSON文件
4. 等待导入完成
5. 查看导入成功提示

### 查看缓存大小
1. 进入设置页面
2. 查看"Data Management"卡片的副标题，显示实际缓存大小
3. 例如：Cache size: 2.1 MB（如果有数据）或Cache size: 0 B（如果没有数据）

### 清除缓存
1. 进入设置 → Data Management
2. 点击"Clear Cache"
3. 确认清清除操作
4. 等待清除完成
5. 缓存大小更新

### 查看存储信息
1. 进入设置 → Data Management
2. 点击"Storage Information"
3. 查看详细的存储使用情况（图片、视频、文本文件、数据库）

### 删除所有数据
1. 进入设置 → Data Management
2. 滚动到"危险区域"(Danger Zone)
3. 点击"Delete All Data"
4. 二次确认
5. 所有数据被删除

### 检查更新
1. 进入设置 → Check for Updates
2. 点击"Check for Updates"按钮
3. 等待检查完成（从GitHub API获取）
4. 如有更新，显示更新对话框和更新日志
5. 点击"Download Update"在浏览器中打开GitHub Releases页面

### 访问GitHub
1. 进入设置 → About
2. 滚动到"Links"部分
3. 点击任意链接在浏览器中打开

## 技术细节

### 依赖包
- `shared_preferences: ^2.3.2` - 设置持久化
- `package_info_plus: ^8.0.0` - 获取应用版本信息
- `url_launcher: ^6.3.0` - 打开链接
- `dio: ^5.7.0` - HTTP请求检查更新
- `file_picker: ^8.0.6` - 选择文件和目录
- `path: ^1.9.0` - 路径处理
- `sqflite_android: ^2.3.0` - Android SQLite 支持（修复 Android 平台 ft5 错误）

### 缓存计算逻辑
```
缓存大小 = results目录大小 + 数据库文件大小
- results目录：~/.local/share/com.promptmemo.prompt_memo/results/
- 数据库文件：~/.local/share/com.promptmemo.prompt_memo/prompt_memo.db
```

### 统一配置
所有版本号和GitHub链接都从 `lib/core/config/app_info.dart` 获取，确保一致性。

### 数据格式
导出的JSON格式示例：
```json
{
  "version": "1.0",
  "exportedAt": "2025-02-03T12:00:00.000",
  "prompts": [...],
  "collections": [...],
  "samples": [...]
}
```

## 注意事项

1. **版本一致性**: 所有页面的版本号都从 `AppInfo.appVersion` 获取，与pubspec.yaml一致
2. **GitHub链接**: 所有GitHub链接都从 `AppInfo` 获取，确保统一
3. **导入冲突**: 导入时同名collection和prompt会跳过，避免重复
4. **文件引用**: 导入时只导入存在的文件，引用不存在的文件会显示警告
5. **数据删除**: 删除所有数据是危险操作，需要二次确认
6. **缓存清理**: 缓存清理只删除results目录中的文件，不删除目录结构
7. **Android SQLite**: 已添加 `sqflite_android: ^2.3.0` 依赖，修复 Android 平台的 "such module : ft5" 错误
   - Android 平台使用 `sqflite_android` 包
   - 其他平台（iOS/Linux/Windows/macOS）使用 `sqflite` 和 `sqflite_common_ffi` 包
   - 同时添加了 `path_provider_android: ^2.1.3` 作为 Android 平台特定的 path_provider 实现

## 测试建议

1. **主题切换**: 测试三种主题模式，重启应用验证持久化
2. **数据导出**: 导出数据，验证JSON格式正确
3. **数据导入**: 导入刚才导出的数据，验证内容一致
4. **缓存计算**: 添加不同类型的文件，验证缓存大小计算准确
5. **缓存清理**: 清理缓存后，验证文件被删除但目录保留
6. **存储信息**: 验证文件分类统计准确
7. **更新检查**: 测试更新检查功能，验证API调用和显示
8. **GitHub链接**: 测试关于页面中的所有链接是否正确跳转到正确的仓库
9. **版本一致性**: 验证About页面、Settings页面、Update页面的版本号一致
