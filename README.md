# Whisper

> 沉浸式听力学习应用

Whisper 是一款 iOS 平台的语言学习应用，通过精读模式和沉浸式泛听模式，帮助用户在听力和阅读中积累词汇。配合间隔重复算法（SM-2），实现高效词汇记忆。

## 特性

### 🎧 沉浸式听力体验

- **精读模式**：逐词交互，点击任意单词查看释义、标记词汇级别
- **泛听模式**：歌词式全屏显示，配合 Focus（专注）和 Ambient（环境）两种子模式
- **AB 循环**：支持单句重复播放，适合精听练习

### 📚 智能词汇管理

- **四级词汇系统**：New → Learning → Level 3 → Known
- **上下文记忆**：自动保存单词出现的原句
- **间隔重复复习**：基于 SM-2 算法，智能安排复习时间

### 🔄 课程导入

- 支持导入 MP3、M4A、WAV、AAC 音频文件
- 支持 SRT 字幕文件
- 自动按文件名配对音频和字幕

## 技术架构

### 模块化设计

```
Whisper/
├── App/                          # 主应用
├── Packages/
│   ├── SharedModels/             # 跨模块共享类型
│   ├── SubtitleKit/              # SRT 解析
│   ├── AudioPlayerKit/           # 音频播放封装
│   ├── VocabularyKit/            # 词汇存储与管理
│   └── SRSKit/                   # SM-2 间隔重复算法
```

### 技术栈

| 类别 | 技术 |
|------|------|
| 平台 | iOS 18.0+ |
| 语言 | Swift 6.0 |
| UI | SwiftUI |
| 数据 | SwiftData |
| 音频 | AVFoundation |
| 包管理 | Swift Package Manager |

### 依赖关系

```
App → SubtitleKit, AudioPlayerKit, VocabularyKit, SRSKit, SharedModels
VocabularyKit → SRSKit, SharedModels
AudioPlayerKit → SharedModels
SubtitleKit → SharedModels
SRSKit → (无依赖)
SharedModels → (无依赖)
```

## 开始使用

### 环境要求

- Xcode 16.0+
- iOS 18.0+ 设备或模拟器

### 构建项目

```bash
# 1. 克隆仓库
git clone https://github.com/YogeLiu/whisper.git
cd whisper

# 2. 生成 Xcode 项目
swift package generate-xcodeproj

# 3. 在 Xcode 中打开
open Whisper.xcodeproj

# 4. 选择目标设备并运行
```

### 使用方法

1. **导入课程**：点击首页右上角 "+" 按钮，选择音频和字幕文件
2. **学习模式**：
   - 进入课程后默认为精读模式，可逐词学习
   - 向左滑动切换到泛听模式
3. **标记生词**：点击任意单词，选择级别（1-3 或掌握）
4. **复习词汇**：点击底部「复习」标签开始闪卡复习

## 项目结构

### 核心模块

| 模块 | 功能 |
|------|------|
| **SharedModels** | 跨模块共享的值类型和协议 |
| **SubtitleKit** | SRT 字幕解析，按时间戳查找字幕 |
| **AudioPlayerKit** | AVFoundation 封装，播放控制、AB循环 |
| **VocabularyKit** | 生词存储、级别管理 |
| **SRSKit** | SM-2 间隔重复算法实现 |

### 数据模型

- **Course**：课程（音频+字幕对）
- **Word**：生词（包含级别、复习信息）
- **SubtitleCue**：字幕条目（时间戳+文本）
- **WordLevel**：词汇级别枚举

## 贡献指南

欢迎提交 Pull Request 或创建 Issue！

### 开发环境

```bash
# 使用 XcodeGen 生成项目
xcodegen generate
```

### 代码规范

- 遵循 Swift API Design Guidelines
- 使用 Swift 6.0 语言特性
- 新增功能需包含单元测试

## 许可证

MIT License - see [LICENSE](LICENSE) for details.

## 后续规划

- [ ] 支持更多字幕格式（VTT、LRC）
- [ ] iPad/Mac 支持
- [ ] 系统词典扩展
- [ ] 复习统计和数据可视化
