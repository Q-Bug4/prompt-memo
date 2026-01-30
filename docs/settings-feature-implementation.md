# 设置功能实现说明

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
  - **获取缓存大小**: 计算缓存目录的占用空间
  - **清除缓存**: 删除缓存目录和清空数据库
  - **删除所有数据**: 删除数据库、缓存和上传目录
  - **存储信息**: 显示详细的存储使用情况
    - 数据库大小
    - 图片数量和大小
    - 视频数量和大小
    - 文本文件数量和大小
    - 缓存大小
    - 总计大小

### 4. 版本更新功能
- **文件**: `lib/features/settings/presentation/screens/update_screen.dart`
- **功能**:
  - 从GitHub API获取最新版本信息
  - 比较当前版本和最新版本
  - 显示更新日志
  - 点击下载链接在浏览器中打开下载页面
  - 显示历史版本信息
  - 错误处理和加载状态显示

### 5. 设置持久化
- **文件**: `lib/features/settings/presentation/providers/settings_providers.dart`
- **功能**:
  - 使用SharedPreferences持久化所有设置
  - 主题模式（system/light/dark）
  - 排序方式
  - 自动保存开关
  - 缓存大小
  - 缩略图显示开关

## 使用方法

### 访问设置
1. 打开应用
2. 点击右上角的设置图标
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

### 清除缓存
1. 进入设置 → Data Management
2. 点击"Clear Cache"
3. 确认清清除操作
4. 等待清除完成
5. 缓存大小更新为0

### 查看存储信息
1. 进入设置 → Data Management
2. 点击"Storage Information"
3. 查看详细的存储使用情况

### 删除所有数据
1. 进入设置 → Data Management
2. 滚动到"危险区域"(Danger Zone)
3. 点击"Delete All Data"
4. 二次确认
5. 所有数据被删除，应用显示提示

### 检查更新
1. 进入设置 → Check for Updates
2. 点击"Check for Updates"按钮
3. 等待检查完成（从GitHub API: Q-Bug4/prompt-memo获取最新版本）
4. 如有更新，显示更新对话框和更新日志
5. 点击"Download Update"在浏览器中打开GitHub Releases页面

### 访问GitHub
1. 进入设置 → About
2. 滑动到"Links"部分
3. 点击"GitHub Repository"跳转到：https://github.com/Q-Bug4/prompt-memo
4. 点击"Report Issues"跳转到：https://github.com/Q-Bug4/prompt-memo/issues
5. 点击"Documentation"跳转到：https://github.com/Q-Bug4/prompt-memo/wiki

## 技术细节

### 依赖包
- `shared_preferences: ^2.3.2` - 设置持久化
- `package_info_plus: ^8.0.0` - 获取应用版本信息
- `url_launcher: ^6.3.0` - 打开下载链接
- `dio: ^5.7.0` - HTTP请求检查更新
- `file_picker: ^8.0.6` - 选择文件和目录

### 数据格式
导出的JSON格式示例：
```json
{
  "version": "1.0",
  "exportedAt": "2024-01-30T12:00:00.000",
  "prompts": [
    {
      "id": "uuid",
      "title": "Prompt Title",
      "content": "Prompt content",
      "tags": ["tag1", "tag2"],
      "collectionId": "collection-uuid",
      "createdAt": "2024-01-01T00:00:00.000",
      "updatedAt": "2024-01-01T00:00:00.000"
    }
  ],
  "collections": [
    {
      "id": "uuid",
      "name": "Collection Name",
      "description": "Description",
      "createdAt": "2024-01-01T00:00:00.000",
      "updatedAt": "2024-01-01T00:00:00.000"
    }
  ],
  "samples": [
    {
      "id": "uuid",
      "promptId": "prompt-uuid",
      "filePath": "/path/to/file",
      "fileName": "file.ext",
      "fileType": "image",
      "fileSize": 1024,
      "createdAt": "2024-01-01T00:00:00.000"
    }
  ]
}
```

## 注意事项

1. **更新检查**: 需要替换GitHub仓库URL为实际的仓库地址
2. **导入冲突**: 导入时同名collection和prompt会跳过，避免重复
3. **文件引用**: 导入时只导入存在的文件，引用不存在的文件会显示警告
4. **数据删除**: 删除所有数据是危险操作，需要二次确认
5. **缓存清理**: 缓存清理包括数据库和缓存目录，请谨慎使用

## 测试建议

1. **主题切换**: 测试三种主题模式，重启应用验证持久化
2. **数据导出**: 导出数据，验证JSON格式正确
3. **数据导入**: 导入刚才导出的数据，验证内容一致
4. **缓存清理**: 添加一些数据，然后清理缓存，验证数据被清空
5. **存储信息**: 添加不同类型的文件，验证统计信息准确
6. **更新检查**: 模拟网络错误，验证错误处理
