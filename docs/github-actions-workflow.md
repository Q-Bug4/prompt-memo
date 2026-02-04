# GitHub Actions Workflow 说明

## 自动生成 Release Notes

### 功能说明
GitHub Actions workflow 现在会自动生成基于 git commits 和 tag message 的 release notes，而不是每次都使用相同的内容。

### 工作原理

1. **获取当前标签**：从 `GITHUB_REF` 环境变量获取当前推送的 tag（如 `v1.1.0`）

2. **获取上一个标签**：使用 `git describe` 命令找到上一个 tag

3. **获取 commits 范围**：
   - 如果是第一个 release，范围是从开始到当前 tag
   - 如果不是第一个 release，范围是从上一个 tag 到当前 tag

4. **获取 tag message**：读取 git tag 的注释（使用 `git tag -l`）

5. **生成 release notes**：
   - 显示当前版本号
   - 显示 tag message（tag 的注释）
   - 列出范围内的所有 commits
   - 包含下载说明

### Release Notes 格式

```markdown
## Prompt Memo v1.1.0

### 📝 Tag Message
这里是 tag 的注释内容

### 📦 What's Changed

- commit message 1
- commit message 2
- commit message 3
...

### 📦 Download

#### Android (.apk)
- 直接下载并安装，无需额外依赖

#### Windows (.zip)
- 解压后运行 `prompt_memo.exe`

#### Linux (.tar.gz)
- 解压后运行 `./run.sh`

---
*Full Changelog: https://github.com/Q-Bug4/prompt-memo/commits/v1.1.0*
```

### 使用方法

#### 方法1：创建带注释的 Tag（推荐）
```bash
# 创建带注释的 tag
git tag -a v1.1.0 -m "Added Settings feature with theme switching and data management"

# 推送 tag
git push origin v1.1.0
```

#### 方法2：推送 Tag 后添加注释（使用 GitHub UI）
```bash
# 创建 tag（不添加注释）
git tag v1.1.0
git push origin v1.1.0

# 然后在 GitHub Releases 页面编辑 Release Notes
```

### Commit Message 最佳实践

为了让 release notes 更清晰，建议遵循以下 commit message 格式：

```bash
# 功能添加
git commit -m "feat: 添加主题切换功能"

# Bug 修复
git commit -m "fix: 修复缓存大小计算错误"

# 性能优化
git commit -m "perf: 优化数据库查询性能"

# 文档更新
git commit -m "docs: 更新用户手册"

# 重构
git commit -m "refactor: 重构数据导出服务"

# 测试
git commit -m "test: 添加单元测试"

# 样式调整
git commit -m "style: 代码格式化"
```

### Tag Message 建议

Tag message 应该简洁地描述本次版本的主要变更：

```bash
# 好的 Tag Message 示例
git tag -a v1.1.0 -m "Settings feature: theme switching, data export/import, cache management, and version checker"

# 更详细的 Tag Message 示例
git tag -a v1.1.0 -m "Major update: Settings feature with theme switching, data export/import, cache management, version checker, and GitHub links"
```

### Workflow 步骤详解

#### 1. 获取当前和上一个 Tag
```yaml
# 获取当前 tag
CURRENT_TAG="${GITHUB_REF#refs/tags/}"

# 获取上一个 tag
PREVIOUS_TAG=$(git describe --tags --abbrev=0 "$CURRENT_TAG^" 2>/dev/null || echo "")
```

#### 2. 获取 Commits
```yaml
# 如果是第一个 release
if [ -z "$PREVIOUS_TAG" ]; then
  COMMITS=$(git log --pretty=format:"- %s" "$CURRENT_TAG" --no-merges)
else
  # 获取上一个 tag 到当前 tag 之间的所有 commits
  COMMITS=$(git log --pretty=format:"- %s" "$RANGE" --no-merges)
fi
```

#### 3. 获取 Tag Message
```yaml
# 获取 tag 的 subject（注释内容）
TAG_MESSAGE=$(git tag -l --format='%(contents:subject)' "$CURRENT_TAG")
```

#### 4. 生成 Release Notes
```yaml
# 生成 markdown 格式的 release notes
cat > release_notes.md << EOF
## Prompt Memo $CURRENT_TAG

### 📝 Tag Message
$TAG_MESSAGE

### 📦 What's Changed

$COMMITS

### 📦 Download
...
EOF
```

### 注意事项

1. **Fetch Depth**：workflow 设置了 `fetch-depth: 0`，这样可以获取完整的 git 历史，确保能够正确找到上一个 tag

2. **No Merges**：使用 `--no-merges` 参数，避免在 release notes 中显示 merge commits

3. **Tag Message**：确保在创建 tag 时添加有意义的注释，这会作为 release notes 的标题部分

4. **自动触发**：workflow 会在推送任何以 `v` 开头的 tag 时自动触发

5. **手动触发**：也可以通过 GitHub Actions UI 手动触发 workflow（workflow_dispatch）

### 示例场景

#### 场景1：首次发布
```bash
# 初始 commit
git add .
git commit -m "Initial commit: basic prompt management"
git push

# 创建并推送 tag
git tag v0.1.0 -m "Initial release"
git push origin v0.1.0
```
Release Notes 会显示所有初始 commits。

#### 场景2：版本更新
```bash
# 添加一些新功能
git commit -m "feat: add theme switching"
git commit -m "feat: add data export"
git commit -m "fix: fix cache calculation bug"
git push

# 创建并推送 tag
git tag v0.2.0 -m "Theme switching and data management"
git push origin v0.2.0
```
Release Notes 只会显示 v0.1.0 到 v0.2.0 之间的三个 commits。

### 故障排除

#### 问题1：Release notes 为空
- 检查 tag 是否正确推送
- 检查 commit messages 是否清晰
- 确认 workflow 有 `contents: write` 权限

#### 问题2：没有找到上一个 tag
- 这是正常的，如果是第一个 release，会显示从项目开始的所有 commits

#### 问题3：Commits 显示不完整
- 确保 commit messages 遵循规范
- 检查是否使用了 merge commits（已排除）

### 相关链接

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Git Tag 最佳实践](https://git-scm.com/book/en/v2/Git-Basics-Tagging.html)
