# LingQ 英语听力学习 App 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个模块化的 iOS 英语听力学习 App，支持 MP3+SRT 导入、精读/泛听双模式、四级生词标记和间隔重复复习。

**Architecture:** 5 个 Swift Package（SharedModels、SubtitleKit、SRSKit、AudioPlayerKit、VocabularyKit）+ 1 个 SwiftUI App target。各 Package 独立可测，App 层负责 UI 组装和导航。SwiftData 做持久化，AVFoundation 做音频播放。

**Tech Stack:** Swift 6, SwiftUI, SwiftData, AVFoundation, NaturalLanguage, iOS 18+

**Spec:** `docs/superpowers/specs/2026-03-20-lingq-listening-app-design.md`

**Figma:** `figma.com/design/f3zPdc6jNwaTW6YlhyVRo5/LingQ`

---

## 文件结构

```
lingQ/
├── App/
│   └── lingQ/
│       ├── lingQApp.swift                    # App 入口、SwiftData container 配置
│       ├── ContentView.swift                 # TabView 根视图
│       ├── Theme/
│       │   ├── AppTheme.swift                # 语义色彩 token 定义
│       │   └── ThemeManager.swift            # 主题切换管理（@AppStorage）
│       ├── Import/
│       │   ├── FileImporter.swift            # 文档选择器封装 + 自动配对逻辑
│       │   └── BookmarkManager.swift         # Security-Scoped Bookmark 管理
│       ├── CourseList/
│       │   ├── CourseListView.swift           # 课程列表页面
│       │   ├── CourseCardView.swift           # 单个课程卡片组件
│       │   └── EmptyStateView.swift          # 空状态提示
│       ├── IntensiveReading/
│       │   ├── IntensiveReadingView.swift     # 精读模式主视图
│       │   ├── ReadingCanvasView.swift        # 可滚动文本画布
│       │   ├── TappableWordView.swift         # 可点击单词组件
│       │   ├── SentenceView.swift             # 单句视图（含高亮状态）
│       │   ├── WordLookupPopup.swift          # 查词弹窗
│       │   └── MiniPlayerView.swift           # 底部浮动胶囊播放器
│       ├── ImmersiveListening/
│       │   ├── ImmersiveListeningView.swift   # 泛听模式主视图
│       │   ├── LyricsCanvasView.swift         # 歌词式字幕画布
│       │   ├── LyricLineView.swift            # 单行歌词组件
│       │   ├── ImmersivePlayerView.swift      # 底部玻璃拟态播放器
│       │   └── ImmersiveMode.swift            # Focused/Ambient 枚举+行为
│       ├── Vocabulary/
│       │   ├── VocabularyListView.swift        # 生词本列表页
│       │   └── WordCardView.swift             # 生词卡片组件
│       └── Review/
│           ├── FlashcardReviewView.swift      # 闪卡复习页
│           ├── FlashcardView.swift            # 单张闪卡（翻转动画）
│           └── ReviewSummaryView.swift        # 复习统计摘要
├── Packages/
│   ├── SharedModels/
│   │   ├── Package.swift
│   │   ├── Sources/SharedModels/
│   │   │   ├── SubtitleCue.swift              # 字幕条目值类型
│   │   │   ├── WordLevel.swift                # 生词级别枚举
│   │   │   └── Course.swift                   # 课程 SwiftData 模型
│   │   └── Tests/SharedModelsTests/
│   │       └── WordLevelTests.swift
│   ├── SubtitleKit/
│   │   ├── Package.swift
│   │   ├── Sources/SubtitleKit/
│   │   │   ├── SRTParser.swift                # SRT 文件解析器
│   │   │   └── CueSearcher.swift              # 二分查找定位字幕
│   │   └── Tests/SubtitleKitTests/
│   │       ├── SRTParserTests.swift
│   │       └── CueSearcherTests.swift
│   ├── SRSKit/
│   │   ├── Package.swift
│   │   ├── Sources/SRSKit/
│   │   │   ├── SM2Algorithm.swift             # SM-2 算法实现
│   │   │   ├── ReviewGrade.swift              # 评分枚举
│   │   │   └── ReviewSchedule.swift           # 调度结果值类型
│   │   └── Tests/SRSKitTests/
│   │       └── SM2AlgorithmTests.swift
│   ├── AudioPlayerKit/
│   │   ├── Package.swift
│   │   ├── Sources/AudioPlayerKit/
│   │   │   └── AudioPlayer.swift              # @Observable 播放器
│   │   └── Tests/AudioPlayerKitTests/
│   │       └── AudioPlayerTests.swift
│   └── VocabularyKit/
│       ├── Package.swift
│       ├── Sources/VocabularyKit/
│       │   ├── Word.swift                     # 生词 SwiftData 模型
│       │   └── VocabularyStore.swift           # 生词增删改查 + 复习调度
│       └── Tests/VocabularyKitTests/
│           ├── WordTests.swift
│           └── VocabularyStoreTests.swift
```

---

## Task 1: 项目脚手架和 Xcode 工程

创建 Xcode 项目和所有 Swift Package 骨架。

**Files:**
- Create: `App/lingQ/lingQApp.swift`
- Create: `App/lingQ/ContentView.swift`
- Create: 所有 5 个 Package 的 `Package.swift`
- Create: 各 Package 的空源文件占位

- [ ] **Step 1: 创建 Xcode 项目**

用 Xcode 创建一个新的 iOS App 项目：
- Product Name: `lingQ`
- Organization Identifier: 用户自定义
- Interface: SwiftUI
- Language: Swift
- Storage: SwiftData
- 最低部署目标: iOS 18.0
- 保存路径: `App/` 目录下

或用命令行初始化基本结构：

```bash
mkdir -p App/lingQ
```

- [ ] **Step 2: 创建 SharedModels Package**

```bash
mkdir -p Packages/SharedModels/Sources/SharedModels
mkdir -p Packages/SharedModels/Tests/SharedModelsTests
```

`Packages/SharedModels/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedModels",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SharedModels", targets: ["SharedModels"]),
    ],
    targets: [
        .target(name: "SharedModels"),
        .testTarget(name: "SharedModelsTests", dependencies: ["SharedModels"]),
    ]
)
```

- [ ] **Step 3: 创建 SRSKit Package**

`Packages/SRSKit/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SRSKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SRSKit", targets: ["SRSKit"]),
    ],
    targets: [
        .target(name: "SRSKit"),
        .testTarget(name: "SRSKitTests", dependencies: ["SRSKit"]),
    ]
)
```

- [ ] **Step 4: 创建 SubtitleKit Package**

`Packages/SubtitleKit/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubtitleKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SubtitleKit", targets: ["SubtitleKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(name: "SubtitleKit", dependencies: ["SharedModels"]),
        .testTarget(name: "SubtitleKitTests", dependencies: ["SubtitleKit"]),
    ]
)
```

- [ ] **Step 5: 创建 AudioPlayerKit Package**

`Packages/AudioPlayerKit/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AudioPlayerKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AudioPlayerKit", targets: ["AudioPlayerKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(name: "AudioPlayerKit", dependencies: ["SharedModels"]),
        .testTarget(name: "AudioPlayerKitTests", dependencies: ["AudioPlayerKit"]),
    ]
)
```

- [ ] **Step 6: 创建 VocabularyKit Package**

`Packages/VocabularyKit/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VocabularyKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "VocabularyKit", targets: ["VocabularyKit"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../SRSKit"),
    ],
    targets: [
        .target(name: "VocabularyKit", dependencies: ["SharedModels", "SRSKit"]),
        .testTarget(name: "VocabularyKitTests", dependencies: ["VocabularyKit"]),
    ]
)
```

- [ ] **Step 7: 在 Xcode 项目中添加所有本地 Package 依赖**

在 `App/lingQ.xcodeproj` 中：
1. File → Add Package Dependencies → Add Local
2. 逐个添加 5 个 Package
3. 确保 lingQ target 链接所有 5 个 library

- [ ] **Step 8: 验证编译通过**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 9: 提交**

```bash
git add -A && git commit -m "feat: scaffold Xcode project and 5 Swift Packages"
```

---

## Task 2: SharedModels — 核心数据类型

**Files:**
- Create: `Packages/SharedModels/Sources/SharedModels/WordLevel.swift`
- Create: `Packages/SharedModels/Sources/SharedModels/SubtitleCue.swift`
- Create: `Packages/SharedModels/Sources/SharedModels/Course.swift`
- Create: `Packages/SharedModels/Tests/SharedModelsTests/WordLevelTests.swift`

- [ ] **Step 1: 编写 WordLevel 测试**

`Packages/SharedModels/Tests/SharedModelsTests/WordLevelTests.swift`:
```swift
import Testing
@testable import SharedModels

@Test func wordLevelRawValues() {
    #expect(WordLevel.new.rawValue == 0)
    #expect(WordLevel.level1.rawValue == 1)
    #expect(WordLevel.level2.rawValue == 2)
    #expect(WordLevel.level3.rawValue == 3)
    #expect(WordLevel.known.rawValue == 4)
}

@Test func wordLevelDisplayName() {
    #expect(WordLevel.level2.displayName == "INTERMEDIATE")
    #expect(WordLevel.known.displayName == "KNOWN")
}

@Test func wordLevelIsLearning() {
    #expect(WordLevel.new.isLearning == false)
    #expect(WordLevel.level1.isLearning == true)
    #expect(WordLevel.level2.isLearning == true)
    #expect(WordLevel.level3.isLearning == true)
    #expect(WordLevel.known.isLearning == false)
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Packages/SharedModels && swift test 2>&1 | tail -10
```

预期：编译失败，WordLevel 未定义

- [ ] **Step 3: 实现 WordLevel**

`Packages/SharedModels/Sources/SharedModels/WordLevel.swift`:
```swift
import Foundation

public enum WordLevel: Int, Codable, Sendable, CaseIterable {
    case new = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case known = 4

    public var displayName: String {
        switch self {
        case .new: "NEW"
        case .level1: "BEGINNER"
        case .level2: "INTERMEDIATE"
        case .level3: "ADVANCED"
        case .known: "KNOWN"
        }
    }

    public var isLearning: Bool {
        switch self {
        case .level1, .level2, .level3: true
        default: false
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Packages/SharedModels && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 5: 实现 SubtitleCue**

`Packages/SharedModels/Sources/SharedModels/SubtitleCue.swift`:
```swift
import Foundation

public struct SubtitleCue: Sendable, Identifiable, Equatable {
    public let id: Int  // SRT 中的序号
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let text: String

    public init(id: Int, startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }

    public func contains(time: TimeInterval) -> Bool {
        time >= startTime && time < endTime
    }
}
```

- [ ] **Step 6: 实现 Course SwiftData 模型**

`Packages/SharedModels/Sources/SharedModels/Course.swift`:
```swift
import Foundation
import SwiftData

@Model
public final class Course {
    public var id: UUID
    public var title: String
    public var audioBookmark: Data  // Security-Scoped Bookmark
    public var subtitleBookmark: Data
    public var createdAt: Date
    public var lastPlayedAt: Date?
    public var playbackPosition: TimeInterval
    public var folder: String?

    public init(
        title: String,
        audioBookmark: Data,
        subtitleBookmark: Data
    ) {
        self.id = UUID()
        self.title = title
        self.audioBookmark = audioBookmark
        self.subtitleBookmark = subtitleBookmark
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }
}
```

- [ ] **Step 7: 验证编译通过**

```bash
cd Packages/SharedModels && swift build 2>&1 | tail -5
```

预期：Build complete

- [ ] **Step 8: 提交**

```bash
git add -A && git commit -m "feat: add SharedModels with WordLevel, SubtitleCue, Course"
```

---

## Task 3: SRSKit — SM-2 间隔重复算法

**Files:**
- Create: `Packages/SRSKit/Sources/SRSKit/ReviewGrade.swift`
- Create: `Packages/SRSKit/Sources/SRSKit/ReviewSchedule.swift`
- Create: `Packages/SRSKit/Sources/SRSKit/SM2Algorithm.swift`
- Create: `Packages/SRSKit/Tests/SRSKitTests/SM2AlgorithmTests.swift`

- [ ] **Step 1: 编写 SM-2 算法测试**

`Packages/SRSKit/Tests/SRSKitTests/SM2AlgorithmTests.swift`:
```swift
import Testing
@testable import SRSKit

@Test func againResetsRepetition() {
    let result = SM2Algorithm.schedule(
        grade: .again,
        repetition: 3,
        easeFactor: 2.5,
        interval: 10
    )
    #expect(result.repetition == 0)
    #expect(result.interval == 1)  // 1 分钟（转换为天时为极小值）
}

@Test func goodUsesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 15)  // 6 * 2.5 = 15
    #expect(result.easeFactor == 2.5)  // good 不改变 easeFactor
}

@Test func easyIncreasesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .easy,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 19)  // 6 * 2.5 * 1.3 ≈ 19.5 取整 19
    #expect(result.easeFactor > 2.5)
}

@Test func hardDecreasesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .hard,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 7)  // 6 * 1.2 = 7.2 取整 7
    #expect(result.easeFactor == 2.35)  // 2.5 - 0.15
}

@Test func easeFactorNeverBelowMinimum() {
    let result = SM2Algorithm.schedule(
        grade: .hard,
        repetition: 2,
        easeFactor: 1.35,
        interval: 6
    )
    #expect(result.easeFactor == 1.3)  // 最低值
}

@Test func firstRepetitionIntervalIsOne() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 0,
        easeFactor: 2.5,
        interval: 0
    )
    #expect(result.interval == 1)
    #expect(result.repetition == 1)
}

@Test func secondRepetitionIntervalIsSix() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 1,
        easeFactor: 2.5,
        interval: 1
    )
    #expect(result.interval == 6)
    #expect(result.repetition == 2)
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Packages/SRSKit && swift test 2>&1 | tail -10
```

预期：编译失败

- [ ] **Step 3: 实现 ReviewGrade 和 ReviewSchedule**

`Packages/SRSKit/Sources/SRSKit/ReviewGrade.swift`:
```swift
public enum ReviewGrade: Sendable {
    case again
    case hard
    case good
    case easy
}
```

`Packages/SRSKit/Sources/SRSKit/ReviewSchedule.swift`:
```swift
public struct ReviewSchedule: Sendable, Equatable {
    public let interval: Int        // 天数
    public let repetition: Int
    public let easeFactor: Double

    public init(interval: Int, repetition: Int, easeFactor: Double) {
        self.interval = interval
        self.repetition = repetition
        self.easeFactor = easeFactor
    }
}
```

- [ ] **Step 4: 实现 SM2Algorithm**

`Packages/SRSKit/Sources/SRSKit/SM2Algorithm.swift`:
```swift
public enum SM2Algorithm {
    private static let minimumEaseFactor: Double = 1.3

    public static func schedule(
        grade: ReviewGrade,
        repetition: Int,
        easeFactor: Double,
        interval: Int
    ) -> ReviewSchedule {
        switch grade {
        case .again:
            return ReviewSchedule(interval: 1, repetition: 0, easeFactor: easeFactor)

        case .hard:
            let newEF = max(easeFactor - 0.15, minimumEaseFactor)
            let newInterval = max(Int(Double(interval) * 1.2), 1)
            return ReviewSchedule(interval: newInterval, repetition: repetition + 1, easeFactor: newEF)

        case .good:
            let newInterval: Int
            switch repetition {
            case 0: newInterval = 1
            case 1: newInterval = 6
            default: newInterval = Int(Double(interval) * easeFactor)
            }
            return ReviewSchedule(interval: newInterval, repetition: repetition + 1, easeFactor: easeFactor)

        case .easy:
            let newEF = easeFactor + 0.15
            let newInterval: Int
            switch repetition {
            case 0: newInterval = 1
            case 1: newInterval = 6
            default: newInterval = Int(Double(interval) * easeFactor * 1.3)
            }
            return ReviewSchedule(interval: newInterval, repetition: repetition + 1, easeFactor: newEF)
        }
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

```bash
cd Packages/SRSKit && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add SRSKit with SM-2 spaced repetition algorithm"
```

---

## Task 4: SubtitleKit — SRT 解析和字幕查找

**Files:**
- Create: `Packages/SubtitleKit/Sources/SubtitleKit/SRTParser.swift`
- Create: `Packages/SubtitleKit/Sources/SubtitleKit/CueSearcher.swift`
- Create: `Packages/SubtitleKit/Tests/SubtitleKitTests/SRTParserTests.swift`
- Create: `Packages/SubtitleKit/Tests/SubtitleKitTests/CueSearcherTests.swift`

- [ ] **Step 1: 编写 SRT 解析测试**

`Packages/SubtitleKit/Tests/SubtitleKitTests/SRTParserTests.swift`:
```swift
import Testing
@testable import SubtitleKit
import SharedModels

@Test func parseValidSRT() throws {
    let srt = """
    1
    00:00:01,000 --> 00:00:04,000
    Hello, welcome to this lesson.

    2
    00:00:05,500 --> 00:00:09,200
    Today we will learn about
    artificial intelligence.

    """
    let cues = try SRTParser.parse(string: srt)
    #expect(cues.count == 2)
    #expect(cues[0].id == 1)
    #expect(cues[0].startTime == 1.0)
    #expect(cues[0].endTime == 4.0)
    #expect(cues[0].text == "Hello, welcome to this lesson.")
    #expect(cues[1].text == "Today we will learn about\nartificial intelligence.")
}

@Test func parseTimestamp() throws {
    let time = SRTParser.parseTimestamp("01:02:03,456")
    #expect(time == 3723.456)
}

@Test func parseEmptyStringReturnsEmpty() throws {
    let cues = try SRTParser.parse(string: "")
    #expect(cues.isEmpty)
}

@Test func parseMalformedSkipsInvalid() throws {
    let srt = """
    1
    INVALID TIMESTAMP
    Some text.

    2
    00:00:05,000 --> 00:00:08,000
    Valid cue.

    """
    let cues = try SRTParser.parse(string: srt)
    #expect(cues.count == 1)
    #expect(cues[0].text == "Valid cue.")
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Packages/SubtitleKit && swift test 2>&1 | tail -10
```

预期：编译失败

- [ ] **Step 3: 实现 SRTParser**

`Packages/SubtitleKit/Sources/SubtitleKit/SRTParser.swift`:
```swift
import Foundation
import SharedModels

public enum SRTParser {
    public static func parse(string: String) throws -> [SubtitleCue] {
        let blocks = string
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var cues: [SubtitleCue] = []
        for block in blocks {
            let lines = block.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
            guard lines.count >= 3,
                  let index = Int(lines[0].trimmingCharacters(in: .whitespaces)),
                  let (start, end) = parseTimestampLine(lines[1])
            else { continue }

            let text = lines[2...].joined(separator: "\n")
            cues.append(SubtitleCue(id: index, startTime: start, endTime: end, text: text))
        }
        return cues
    }

    public static func parse(fileURL: URL) throws -> [SubtitleCue] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parse(string: content)
    }

    static func parseTimestampLine(_ line: String) -> (TimeInterval, TimeInterval)? {
        let parts = line.components(separatedBy: " --> ")
        guard parts.count == 2,
              let start = parseTimestamp(parts[0].trimmingCharacters(in: .whitespaces)),
              let end = parseTimestamp(parts[1].trimmingCharacters(in: .whitespaces))
        else { return nil }
        return (start, end)
    }

    public static func parseTimestamp(_ string: String) -> TimeInterval? {
        // 格式: HH:MM:SS,mmm
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2])
        else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Packages/SubtitleKit && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 5: 编写 CueSearcher 测试**

`Packages/SubtitleKit/Tests/SubtitleKitTests/CueSearcherTests.swift`:
```swift
import Testing
@testable import SubtitleKit
import SharedModels

@Test func findCueAtTime() {
    let cues = [
        SubtitleCue(id: 1, startTime: 0, endTime: 3, text: "First"),
        SubtitleCue(id: 2, startTime: 3, endTime: 6, text: "Second"),
        SubtitleCue(id: 3, startTime: 7, endTime: 10, text: "Third"),
    ]
    let searcher = CueSearcher(cues: cues)

    #expect(searcher.cue(at: 1.5)?.id == 1)
    #expect(searcher.cue(at: 4.0)?.id == 2)
    #expect(searcher.cue(at: 8.0)?.id == 3)
}

@Test func returnsNilForGap() {
    let cues = [
        SubtitleCue(id: 1, startTime: 0, endTime: 3, text: "First"),
        SubtitleCue(id: 2, startTime: 5, endTime: 8, text: "Second"),
    ]
    let searcher = CueSearcher(cues: cues)
    #expect(searcher.cue(at: 4.0) == nil)  // 在间隙中
}

@Test func returnsNilForEmptyCues() {
    let searcher = CueSearcher(cues: [])
    #expect(searcher.cue(at: 1.0) == nil)
}

@Test func findNextCue() {
    let cues = [
        SubtitleCue(id: 1, startTime: 0, endTime: 3, text: "First"),
        SubtitleCue(id: 2, startTime: 3, endTime: 6, text: "Second"),
        SubtitleCue(id: 3, startTime: 7, endTime: 10, text: "Third"),
    ]
    let searcher = CueSearcher(cues: cues)

    #expect(searcher.nextCue(after: 1.5)?.id == 2)
    #expect(searcher.nextCue(after: 8.0)?.id == nil)  // 最后一个之后无下一个
}

@Test func findPreviousCue() {
    let cues = [
        SubtitleCue(id: 1, startTime: 0, endTime: 3, text: "First"),
        SubtitleCue(id: 2, startTime: 3, endTime: 6, text: "Second"),
        SubtitleCue(id: 3, startTime: 7, endTime: 10, text: "Third"),
    ]
    let searcher = CueSearcher(cues: cues)

    #expect(searcher.previousCue(before: 4.0)?.id == 1)
    #expect(searcher.previousCue(before: 0.5) == nil)  // 第一个之前无前一个
}
```

- [ ] **Step 6: 实现 CueSearcher**

`Packages/SubtitleKit/Sources/SubtitleKit/CueSearcher.swift`:
```swift
import Foundation
import SharedModels

public struct CueSearcher: Sendable {
    private let cues: [SubtitleCue]

    public init(cues: [SubtitleCue]) {
        self.cues = cues.sorted { $0.startTime < $1.startTime }
    }

    public func cue(at time: TimeInterval) -> SubtitleCue? {
        // 二分查找
        var low = 0
        var high = cues.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let c = cues[mid]
            if c.contains(time: time) {
                return c
            } else if time < c.startTime {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        return nil
    }

    public func index(at time: TimeInterval) -> Int? {
        cues.firstIndex { $0.contains(time: time) }
    }

    public func nextCue(after time: TimeInterval) -> SubtitleCue? {
        guard let idx = index(at: time), idx + 1 < cues.count else { return nil }
        return cues[idx + 1]
    }

    public func previousCue(before time: TimeInterval) -> SubtitleCue? {
        guard let idx = index(at: time), idx > 0 else { return nil }
        return cues[idx - 1]
    }

    public var allCues: [SubtitleCue] { cues }
}
```

- [ ] **Step 7: 运行全部测试**

```bash
cd Packages/SubtitleKit && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 8: 提交**

```bash
git add -A && git commit -m "feat: add SubtitleKit with SRT parser and binary search"
```

---

## Task 5: AudioPlayerKit — 音频播放封装

**Files:**
- Create: `Packages/AudioPlayerKit/Sources/AudioPlayerKit/AudioPlayer.swift`
- Create: `Packages/AudioPlayerKit/Tests/AudioPlayerKitTests/AudioPlayerTests.swift`

- [ ] **Step 1: 编写 AudioPlayer 基本测试**

`Packages/AudioPlayerKit/Tests/AudioPlayerKitTests/AudioPlayerTests.swift`:
```swift
import Testing
@testable import AudioPlayerKit

@Test func initialStateIsStopped() {
    let player = AudioPlayer()
    #expect(player.isPlaying == false)
    #expect(player.currentTime == 0)
    #expect(player.duration == 0)
    #expect(player.playbackRate == 1.0)
}

@Test func playbackRateClamped() {
    let player = AudioPlayer()
    player.playbackRate = 3.0
    #expect(player.playbackRate == 2.0)
    player.playbackRate = 0.1
    #expect(player.playbackRate == 0.5)
}

@Test func loopRangeCanBeSet() {
    let player = AudioPlayer()
    player.loopRange = 5.0...10.0
    #expect(player.loopRange != nil)
    player.loopRange = nil
    #expect(player.loopRange == nil)
}
```

- [ ] **Step 2: 实现 AudioPlayer**

`Packages/AudioPlayerKit/Sources/AudioPlayerKit/AudioPlayer.swift`:
```swift
import AVFoundation
import Observation

@Observable
public final class AudioPlayer {
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    public var playbackRate: Float = 1.0 {
        didSet {
            playbackRate = min(max(playbackRate, 0.5), 2.0)
            avPlayer?.rate = isPlaying ? playbackRate : 0
        }
    }

    public var loopRange: ClosedRange<TimeInterval>?

    private var avPlayer: AVAudioPlayer?
    private var timer: Timer?

    public init() {}

    public func load(url: URL) throws {
        let player = try AVAudioPlayer(contentsOf: url)
        player.enableRate = true
        player.prepareToPlay()
        self.avPlayer = player
        self.duration = player.duration
        self.currentTime = 0
    }

    public func play() {
        guard let avPlayer else { return }
        avPlayer.rate = playbackRate
        avPlayer.play()
        isPlaying = true
        startTimer()
    }

    public func pause() {
        avPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    public func toggle() {
        isPlaying ? pause() : play()
    }

    public func seek(to time: TimeInterval) {
        let clamped = min(max(time, 0), duration)
        avPlayer?.currentTime = clamped
        currentTime = clamped
    }

    public func skipForward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime + seconds)
    }

    public func skipBackward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime - seconds)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let avPlayer = self.avPlayer else { return }
            self.currentTime = avPlayer.currentTime

            if let range = self.loopRange, self.currentTime >= range.upperBound {
                self.seek(to: range.lowerBound)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public static func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }
}
```

- [ ] **Step 3: 运行测试确认通过**

```bash
cd Packages/AudioPlayerKit && swift test 2>&1 | tail -10
```

预期：All tests passed（注意：load/play/pause 需要真实音频文件，只测试状态初始化和速率钳制）

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: add AudioPlayerKit with Observable audio player"
```

---

## Task 6: VocabularyKit — 生词管理

**Files:**
- Create: `Packages/VocabularyKit/Sources/VocabularyKit/Word.swift`
- Create: `Packages/VocabularyKit/Sources/VocabularyKit/VocabularyStore.swift`
- Create: `Packages/VocabularyKit/Tests/VocabularyKitTests/WordTests.swift`
- Create: `Packages/VocabularyKit/Tests/VocabularyKitTests/VocabularyStoreTests.swift`

- [ ] **Step 1: 编写 Word 模型测试**

`Packages/VocabularyKit/Tests/VocabularyKitTests/WordTests.swift`:
```swift
import Testing
@testable import VocabularyKit
import SharedModels

@Test func wordDefaultValues() {
    let word = Word(text: "equilibrium", contextSentence: "A sense of equilibrium.")
    #expect(word.text == "equilibrium")
    #expect(word.level == .new)
    #expect(word.reviewCount == 0)
    #expect(word.easeFactor == 2.5)
    #expect(word.contextSentence == "A sense of equilibrium.")
}

@Test func wordIsDueForReview() {
    let word = Word(text: "test", contextSentence: nil)
    word.nextReviewAt = Date.distantPast
    #expect(word.isDueForReview == true)

    word.nextReviewAt = Date.distantFuture
    #expect(word.isDueForReview == false)

    word.nextReviewAt = nil
    #expect(word.isDueForReview == false)
}
```

- [ ] **Step 2: 实现 Word SwiftData 模型**

`Packages/VocabularyKit/Sources/VocabularyKit/Word.swift`:
```swift
import Foundation
import SwiftData
import SharedModels

@Model
public final class Word {
    public var id: UUID
    public var text: String
    public var lemma: String?
    public var level: WordLevel
    public var definition: String?
    public var phonetic: String?
    public var contextSentence: String?
    public var courseId: UUID?
    public var createdAt: Date
    public var nextReviewAt: Date?
    public var reviewCount: Int
    public var easeFactor: Double

    public init(text: String, contextSentence: String?) {
        self.id = UUID()
        self.text = text.lowercased()
        self.lemma = nil
        self.level = .new
        self.definition = nil
        self.phonetic = nil
        self.contextSentence = contextSentence
        self.courseId = nil
        self.createdAt = Date()
        self.nextReviewAt = nil
        self.reviewCount = 0
        self.easeFactor = 2.5
    }

    public var isDueForReview: Bool {
        guard let nextReviewAt else { return false }
        return nextReviewAt <= Date()
    }
}
```

- [ ] **Step 3: 运行测试确认通过**

```bash
cd Packages/VocabularyKit && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 4: 实现 VocabularyStore**

`Packages/VocabularyKit/Sources/VocabularyKit/VocabularyStore.swift`:
```swift
import Foundation
import SwiftData
import SharedModels
import SRSKit

public struct VocabularyStore: Sendable {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func addWord(_ text: String, level: WordLevel, contextSentence: String?, courseId: UUID?) throws {
        // 去重：如果已存在相同文本的词，更新级别
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.level = level
            if let ctx = contextSentence { existing.contextSentence = ctx }
            return
        }

        let word = Word(text: text, contextSentence: contextSentence)
        word.level = level
        word.courseId = courseId
        modelContext.insert(word)
    }

    public func updateLevel(word: Word, to level: WordLevel) {
        word.level = level
        if level == .level1 && word.nextReviewAt == nil {
            // 首次标记为学习，设置初次复习
            word.nextReviewAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
    }

    public func gradeReview(word: Word, grade: ReviewGrade) {
        let schedule = SM2Algorithm.schedule(
            grade: grade,
            repetition: word.reviewCount,
            easeFactor: word.easeFactor,
            interval: currentInterval(for: word)
        )
        word.reviewCount = schedule.repetition
        word.easeFactor = schedule.easeFactor
        word.nextReviewAt = Calendar.current.date(byAdding: .day, value: schedule.interval, to: Date())
    }

    public func wordsForReview() throws -> [Word] {
        let now = Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.nextReviewAt != nil && word.nextReviewAt! <= now
            },
            sortBy: [SortDescriptor(\.nextReviewAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func wordCount(level: WordLevel, courseId: UUID? = nil) throws -> Int {
        var descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.level == level }
        )
        descriptor.propertiesToFetch = []
        return try modelContext.fetchCount(descriptor)
    }

    private func currentInterval(for word: Word) -> Int {
        guard let nextReview = word.nextReviewAt else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: word.createdAt, to: nextReview).day ?? 0, 0)
    }
}
```

- [ ] **Step 5: 运行全部测试**

```bash
cd Packages/VocabularyKit && swift test 2>&1 | tail -10
```

预期：All tests passed

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add VocabularyKit with Word model and VocabularyStore"
```

---

## Task 7: 主题系统和 App 基础设置

**Files:**
- Create: `App/lingQ/Theme/AppTheme.swift`
- Create: `App/lingQ/Theme/ThemeManager.swift`
- Modify: `App/lingQ/lingQApp.swift`
- Modify: `App/lingQ/ContentView.swift`

- [ ] **Step 1: 实现 AppTheme 语义色彩**

`App/lingQ/Theme/AppTheme.swift`:
```swift
import SwiftUI

enum AppTheme {
    // 深色
    static let darkBackground = Color(hex: "0D1117")
    static let darkSurface = Color(hex: "1C2333")
    static let darkAccent = Color(hex: "4A90D9")

    // 浅色
    static let lightBackground = Color(hex: "F8F9FB")
    static let lightSurface = Color.white
    static let lightAccent = Color(hex: "6C5CE7")

    // 生词级别颜色
    static let level1Color = Color.green
    static let level2Color = Color.purple
    static let level3Color = Color.blue
    static let knownColor = Color.gray
    static let newColor = Color.cyan.opacity(0.5)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            (r, g, b) = (Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: 实现 ThemeManager**

`App/lingQ/Theme/ThemeManager.swift`:
```swift
import SwiftUI

@Observable
final class ThemeManager {
    enum ThemeMode: String, CaseIterable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"
    }

    var mode: ThemeMode {
        get { ThemeMode(rawValue: storedMode) ?? .system }
        set { storedMode = newValue.rawValue }
    }

    @AppStorage("themeMode") private var storedMode = ThemeMode.system.rawValue

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
```

- [ ] **Step 3: 设置 lingQApp 入口**

`App/lingQ/lingQApp.swift`:
```swift
import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit
import AudioPlayerKit

@main
struct lingQApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
                .environment(themeManager)
        }
        .modelContainer(for: [Course.self, Word.self])
    }

    init() {
        AudioPlayer.configureAudioSession()
    }
}
```

- [ ] **Step 4: 设置 ContentView TabView 骨架**

`App/lingQ/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("课程", systemImage: "books.vertical") {
                NavigationStack {
                    Text("课程列表")
                        .navigationTitle("我的课程")
                }
            }

            Tab("生词本", systemImage: "character.book.closed") {
                NavigationStack {
                    Text("生词本")
                        .navigationTitle("生词本")
                }
            }

            Tab("复习", systemImage: "sparkles.rectangle.stack") {
                NavigationStack {
                    Text("闪卡复习")
                        .navigationTitle("复习")
                }
            }
        }
    }
}
```

- [ ] **Step 5: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add theme system and TabView app shell"
```

---

## Task 8: 文件导入和课程列表

**Files:**
- Create: `App/lingQ/Import/BookmarkManager.swift`
- Create: `App/lingQ/Import/FileImporter.swift`
- Create: `App/lingQ/CourseList/CourseListView.swift`
- Create: `App/lingQ/CourseList/CourseCardView.swift`
- Create: `App/lingQ/CourseList/EmptyStateView.swift`

- [ ] **Step 1: 实现 BookmarkManager**

`App/lingQ/Import/BookmarkManager.swift`:
```swift
import Foundation

enum BookmarkManager {
    static func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            // 书签过期，需重新创建（调用者负责）
        }
        return url
    }
}
```

- [ ] **Step 2: 实现 EmptyStateView**

`App/lingQ/CourseList/EmptyStateView.swift`:
```swift
import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("暂无课程", systemImage: "square.and.arrow.down")
        } description: {
            Text("导入 MP3 音频和 SRT 字幕文件开始学习")
        } actions: {
            Button("导入文件", action: onImport)
                .buttonStyle(.borderedProminent)
        }
    }
}
```

- [ ] **Step 3: 实现 CourseCardView**

`App/lingQ/CourseList/CourseCardView.swift`:
```swift
import SwiftUI
import SharedModels

struct CourseCardView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title)
                .font(.headline.italic())

            HStack(spacing: 6) {
                if let lastPlayed = course.lastPlayedAt {
                    Text(lastPlayed, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if course.playbackPosition > 0 {
                ProgressView(value: course.playbackPosition, total: 1.0)
                    .tint(.accent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 4: 实现 CourseListView**

`App/lingQ/CourseList/CourseListView.swift`:
```swift
import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    @State private var showAudioImporter = false
    @State private var showSubtitleImporter = false
    @State private var pendingAudioBookmark: Data?
    @State private var pendingAudioName: String?

    var body: some View {
        Group {
            if courses.isEmpty {
                EmptyStateView { showAudioImporter = true }
            } else {
                List {
                    ForEach(courses) { course in
                        NavigationLink(value: course) {
                            CourseCardView(course: course)
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("我的课程")
        .toolbar {
            if !courses.isEmpty {
                Button("导入", systemImage: "plus") {
                    showAudioImporter = true
                }
            }
        }
        .fileImporter(isPresented: $showAudioImporter, allowedContentTypes: [.audio]) { result in
            handleAudioImport(result)
        }
        .fileImporter(isPresented: $showSubtitleImporter, allowedContentTypes: [.plainText]) { result in
            handleSubtitleImport(result)
        }
    }

    private func handleAudioImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            pendingAudioBookmark = try BookmarkManager.createBookmark(for: url)
            pendingAudioName = url.deletingPathExtension().lastPathComponent

            // 尝试自动查找同名 SRT
            let srtURL = url.deletingPathExtension().appendingPathExtension("srt")
            if FileManager.default.fileExists(atPath: srtURL.path) {
                guard srtURL.startAccessingSecurityScopedResource() else {
                    showSubtitleImporter = true
                    return
                }
                defer { srtURL.stopAccessingSecurityScopedResource() }
                let srtBookmark = try BookmarkManager.createBookmark(for: srtURL)
                createCourse(audioBookmark: pendingAudioBookmark!, subtitleBookmark: srtBookmark, title: pendingAudioName!)
            } else {
                showSubtitleImporter = true
            }
        } catch {
            // 导入失败
        }
    }

    private func handleSubtitleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result,
              let audioBookmark = pendingAudioBookmark,
              let name = pendingAudioName
        else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let srtBookmark = try BookmarkManager.createBookmark(for: url)
            createCourse(audioBookmark: audioBookmark, subtitleBookmark: srtBookmark, title: name)
        } catch {
            // 导入失败
        }
        pendingAudioBookmark = nil
        pendingAudioName = nil
    }

    private func createCourse(audioBookmark: Data, subtitleBookmark: Data, title: String) {
        let course = Course(title: title, audioBookmark: audioBookmark, subtitleBookmark: subtitleBookmark)
        modelContext.insert(course)
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}
```

- [ ] **Step 5: 更新 ContentView 使用 CourseListView**

替换 ContentView 中课程 Tab 的占位文本：
```swift
Tab("课程", systemImage: "books.vertical") {
    NavigationStack {
        CourseListView()
    }
}
```

- [ ] **Step 6: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 7: 提交**

```bash
git add -A && git commit -m "feat: add course list with file import and auto-pairing"
```

---

## Task 9: 精读模式 — 阅读画布和播放器

**Files:**
- Create: `App/lingQ/IntensiveReading/IntensiveReadingView.swift`
- Create: `App/lingQ/IntensiveReading/ReadingCanvasView.swift`
- Create: `App/lingQ/IntensiveReading/TappableWordView.swift`
- Create: `App/lingQ/IntensiveReading/SentenceView.swift`
- Create: `App/lingQ/IntensiveReading/MiniPlayerView.swift`

- [ ] **Step 1: 实现 TappableWordView**

`App/lingQ/IntensiveReading/TappableWordView.swift`:
```swift
import SwiftUI
import SharedModels

struct TappableWordView: View {
    let word: String
    let level: WordLevel?
    let onTap: () -> Void

    var body: some View {
        Text(word)
            .underline(level?.isLearning == true, color: underlineColor)
            .foregroundStyle(level == .known ? .secondary : .primary)
            .onTapGesture(perform: onTap)
    }

    private var underlineColor: Color {
        switch level {
        case .level1: AppTheme.level1Color
        case .level2: AppTheme.level2Color
        case .level3: AppTheme.level3Color
        default: .clear
        }
    }
}
```

- [ ] **Step 2: 实现 SentenceView**

`App/lingQ/IntensiveReading/SentenceView.swift`:
```swift
import SwiftUI
import SharedModels
import NaturalLanguage

struct SentenceView: View {
    let cue: SubtitleCue
    let isCurrentlyPlaying: Bool
    let wordLevels: [String: WordLevel]
    let onWordTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(tokenize(cue.text), id: \.self) { word in
                TappableWordView(
                    word: word,
                    level: wordLevels[word.lowercased()],
                    onTap: { onWordTap(word) }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isCurrentlyPlaying ? Color.accentColor.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 3: 实现 MiniPlayerView**

`App/lingQ/IntensiveReading/MiniPlayerView.swift`:
```swift
import SwiftUI
import AudioPlayerKit

struct MiniPlayerView: View {
    @Bindable var player: AudioPlayer
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // 进度条
            ProgressView(value: player.currentTime, total: max(player.duration, 1))
                .tint(.accent)

            HStack(spacing: 24) {
                // 时间
                Text(formatTime(player.currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                // 控制按钮
                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                }

                Button(action: { player.toggle() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .frame(width: 48, height: 48)
                .background(.accent, in: Circle())
                .foregroundStyle(.white)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                }

                Spacer()

                // 总时长
                Text(formatTime(player.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

- [ ] **Step 4: 实现 IntensiveReadingView**

`App/lingQ/IntensiveReading/IntensiveReadingView.swift`:
```swift
import SwiftUI
import SwiftData
import SharedModels
import SubtitleKit
import AudioPlayerKit
import VocabularyKit

struct IntensiveReadingView: View {
    let course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var player = AudioPlayer()
    @State private var cues: [SubtitleCue] = []
    @State private var searcher: CueSearcher?
    @State private var selectedWord: String?
    @State private var showLookup = false
    @Query private var words: [Word]

    private var wordLevels: [String: WordLevel] {
        Dictionary(uniqueKeysWithValues: words.map { ($0.text, $0.level) })
    }

    private var currentCueIndex: Int? {
        searcher?.index(at: player.currentTime)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 阅读画布
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cues) { cue in
                            SentenceView(
                                cue: cue,
                                isCurrentlyPlaying: searcher?.cue(at: player.currentTime)?.id == cue.id,
                                wordLevels: wordLevels,
                                onWordTap: { word in
                                    selectedWord = word
                                    showLookup = true
                                }
                            )
                            .id(cue.id)
                            .onTapGesture {
                                player.seek(to: cue.startTime)
                            }
                        }
                    }
                    .padding(.bottom, 100)  // 为播放器留空间
                }
                .onChange(of: currentCueIndex) { _, newIndex in
                    if let id = newIndex {
                        withAnimation {
                            proxy.scrollTo(cues[id].id, anchor: .center)
                        }
                    }
                }
            }

            // 底部播放器
            MiniPlayerView(
                player: player,
                onPrevious: {
                    if let prev = searcher?.previousCue(before: player.currentTime) {
                        player.seek(to: prev.startTime)
                    }
                },
                onNext: {
                    if let next = searcher?.nextCue(after: player.currentTime) {
                        player.seek(to: next.startTime)
                    }
                }
            )
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLookup) {
            if let word = selectedWord {
                WordLookupPopup(
                    word: word,
                    contextSentence: searcher?.cue(at: player.currentTime)?.text,
                    courseId: course.id,
                    modelContext: modelContext
                )
                .presentationDetents([.medium])
            }
        }
        .task {
            await loadContent()
        }
        .onDisappear {
            course.playbackPosition = player.currentTime
            course.lastPlayedAt = Date()
            player.pause()
        }
    }

    private func loadContent() async {
        do {
            let subtitleURL = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try BookmarkManager.resolveBookmark(course.audioBookmark)
            try player.load(url: audioURL)
            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }
        } catch {
            // 加载失败处理
        }
    }
}
```

- [ ] **Step 5: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add intensive reading mode with tappable words and player"
```

---

## Task 10: 查词弹窗

**Files:**
- Create: `App/lingQ/IntensiveReading/WordLookupPopup.swift`

- [ ] **Step 1: 实现 WordLookupPopup**

`App/lingQ/IntensiveReading/WordLookupPopup.swift`:
```swift
import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit
import UIKit

struct WordLookupPopup: View {
    let word: String
    let contextSentence: String?
    let courseId: UUID?
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var definition: String = ""
    @State private var currentLevel: WordLevel = .new

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题行
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(.title.bold())
                    if let level = currentLevel.isLearning ? currentLevel : nil {
                        Text("LEVEL \(level.rawValue) · \(level.displayName)")
                            .font(.caption.bold())
                            .foregroundStyle(colorForLevel(level))
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }

            // 释义
            VStack(alignment: .leading, spacing: 4) {
                Text("DEFINITION")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(definition.isEmpty ? "查找中..." : definition)
                    .font(.body)
            }

            // 级别按钮
            HStack(spacing: 12) {
                ForEach([WordLevel.level1, .level2, .level3, .known], id: \.rawValue) { level in
                    Button {
                        setLevel(level)
                    } label: {
                        if level == .known {
                            Image(systemName: "checkmark")
                                .frame(width: 36, height: 36)
                        } else {
                            Text("\(level.rawValue)")
                                .frame(width: 36, height: 36)
                        }
                    }
                    .background(
                        Circle()
                            .fill(colorForLevel(level).opacity(currentLevel == level ? 1 : 0.2))
                    )
                    .foregroundStyle(currentLevel == level ? .white : .primary)
                    .clipShape(Circle())
                }

                Spacer()

                // 发音按钮
                Button {
                    speakWord()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .frame(width: 36, height: 36)
                }
                .background(Circle().fill(.ultraThinMaterial))
            }

            // 上下文句子
            if let ctx = contextSentence {
                Text(ctx)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(24)
        .task {
            loadDefinition()
            loadCurrentLevel()
        }
    }

    private func colorForLevel(_ level: WordLevel) -> Color {
        switch level {
        case .new: AppTheme.newColor
        case .level1: AppTheme.level1Color
        case .level2: AppTheme.level2Color
        case .level3: AppTheme.level3Color
        case .known: AppTheme.knownColor
        }
    }

    private func loadDefinition() {
        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: word) {
            definition = "点击查看系统词典释义"
            // 实际集成时可使用 DCSCopyTextDefinition 或展示 UIReferenceLibraryViewController
        } else {
            definition = "未找到释义"
        }
    }

    private func loadCurrentLevel() {
        let lowered = word.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        if let existing = try? modelContext.fetch(descriptor).first {
            currentLevel = existing.level
        }
    }

    private func setLevel(_ level: WordLevel) {
        currentLevel = level
        let store = VocabularyStore(modelContext: modelContext)
        try? store.addWord(word, level: level, contextSentence: contextSentence, courseId: courseId)
    }

    private func speakWord() {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        AVSpeechSynthesizer().speak(utterance)
    }
}

import AVFoundation
```

- [ ] **Step 2: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add word lookup popup with level buttons and TTS"
```

---

## Task 11: 泛听模式 — 歌词画布和播放器

**Files:**
- Create: `App/lingQ/ImmersiveListening/ImmersiveMode.swift`
- Create: `App/lingQ/ImmersiveListening/LyricLineView.swift`
- Create: `App/lingQ/ImmersiveListening/LyricsCanvasView.swift`
- Create: `App/lingQ/ImmersiveListening/ImmersivePlayerView.swift`
- Create: `App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`

- [ ] **Step 1: 实现 ImmersiveMode 枚举**

`App/lingQ/ImmersiveListening/ImmersiveMode.swift`:
```swift
enum ImmersiveMode: String, CaseIterable {
    case focused = "FOCUSED"
    case ambient = "AMBIENT"

    var autoPauseDelay: TimeInterval? {
        switch self {
        case .focused: 0.8
        case .ambient: nil
        }
    }

    var showWordStatus: Bool {
        switch self {
        case .focused: true
        case .ambient: false
        }
    }
}
```

- [ ] **Step 2: 实现 LyricLineView**

`App/lingQ/ImmersiveListening/LyricLineView.swift`:
```swift
import SwiftUI
import SharedModels

struct LyricLineView: View {
    let text: String
    let state: LyricState
    let onTap: () -> Void

    enum LyricState {
        case past(distance: Int)     // 已过句子，distance=与当前句的距离
        case current
        case future(distance: Int)
    }

    var body: some View {
        Text(text)
            .font(state.isCurrent ? .title.bold() : .body)
            .multilineTextAlignment(.center)
            .opacity(state.opacity)
            .scaleEffect(state.isCurrent ? 1.0 : 0.95)
            .shadow(color: state.isCurrent ? .accent.opacity(0.3) : .clear, radius: 20)
            .animation(.easeInOut(duration: 0.5), value: state.isCurrent)
            .onTapGesture(perform: onTap)
            .padding(.vertical, 8)
    }
}

extension LyricLineView.LyricState {
    var isCurrent: Bool {
        if case .current = self { return true }
        return false
    }

    var opacity: Double {
        switch self {
        case .current: 1.0
        case .past(let d), .future(let d):
            max(0.08, 0.4 - Double(d) * 0.1)
        }
    }
}
```

- [ ] **Step 3: 实现 LyricsCanvasView**

`App/lingQ/ImmersiveListening/LyricsCanvasView.swift`:
```swift
import SwiftUI
import SharedModels

struct LyricsCanvasView: View {
    let cues: [SubtitleCue]
    let currentIndex: Int?
    let onCueTap: (SubtitleCue) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer(minLength: 200)

                    ForEach(Array(cues.enumerated()), id: \.element.id) { index, cue in
                        LyricLineView(
                            text: cue.text,
                            state: lyricState(for: index),
                            onTap: { onCueTap(cue) }
                        )
                        .id(cue.id)
                    }

                    Spacer(minLength: 200)
                }
                .padding(.horizontal, 32)
            }
            .onChange(of: currentIndex) { _, newIndex in
                if let id = newIndex.flatMap({ cues[safe: $0]?.id }) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func lyricState(for index: Int) -> LyricLineView.LyricState {
        guard let current = currentIndex else { return .future(distance: 0) }
        if index == current { return .current }
        if index < current { return .past(distance: current - index) }
        return .future(distance: index - current)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

- [ ] **Step 4: 实现 ImmersivePlayerView**

`App/lingQ/ImmersiveListening/ImmersivePlayerView.swift`:
```swift
import SwiftUI
import AudioPlayerKit

struct ImmersivePlayerView: View {
    @Bindable var player: AudioPlayer
    @Binding var mode: ImmersiveMode
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 进度条
            VStack(spacing: 4) {
                ProgressView(value: player.currentTime, total: max(player.duration, 1))
                    .tint(.accent)
                HStack {
                    Text(formatTime(player.currentTime))
                    Spacer()
                    Text(formatTime(player.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            // 控制按钮
            HStack(spacing: 20) {
                Button { player.skipBackward(10) } label: {
                    Image(systemName: "gobackward.10")
                }

                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                }

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(width: 64, height: 64)
                .background(.accent, in: Circle())
                .foregroundStyle(.white)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                }

                Button { player.skipForward(10) } label: {
                    Image(systemName: "goforward.10")
                }
            }
            .font(.title3)

            // 模式切换标签
            HStack(spacing: 32) {
                ForEach(ImmersiveMode.allCases, id: \.self) { m in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(m == mode ? Color.accent : .clear)
                            .frame(width: 4, height: 4)
                        Text(m.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(m == mode ? .primary : .secondary)
                    }
                    .onTapGesture { mode = m }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

- [ ] **Step 5: 实现 ImmersiveListeningView**

`App/lingQ/ImmersiveListening/ImmersiveListeningView.swift`:
```swift
import SwiftUI
import SharedModels
import SubtitleKit
import AudioPlayerKit

struct ImmersiveListeningView: View {
    let course: Course
    let cues: [SubtitleCue]
    let searcher: CueSearcher
    @Bindable var player: AudioPlayer

    @Environment(\.dismiss) private var dismiss
    @State private var mode: ImmersiveMode = .focused
    @State private var currentIndex: Int?

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            // 歌词画布
            LyricsCanvasView(
                cues: cues,
                currentIndex: currentIndex,
                onCueTap: { cue in
                    player.seek(to: cue.startTime)
                }
            )
            .padding(.bottom, 200)

            // 播放器
            ImmersivePlayerView(
                player: player,
                mode: $mode,
                onPrevious: {
                    if let prev = searcher.previousCue(before: player.currentTime) {
                        player.seek(to: prev.startTime)
                    }
                },
                onNext: {
                    if let next = searcher.nextCue(after: player.currentTime) {
                        player.seek(to: next.startTime)
                    }
                }
            )
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .padding()
            }
        }
        .overlay(alignment: .top) {
            // FLOW STATE 指示器
            Text("FLOW STATE")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .onChange(of: player.currentTime) { _, time in
            currentIndex = searcher.index(at: time)
        }
    }
}
```

- [ ] **Step 6: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 7: 提交**

```bash
git add -A && git commit -m "feat: add immersive listening mode with lyrics canvas and focused/ambient modes"
```

---

## Task 12: 生词本页面

**Files:**
- Create: `App/lingQ/Vocabulary/WordCardView.swift`
- Create: `App/lingQ/Vocabulary/VocabularyListView.swift`

- [ ] **Step 1: 实现 WordCardView**

`App/lingQ/Vocabulary/WordCardView.swift`:
```swift
import SwiftUI
import SharedModels
import VocabularyKit

struct WordCardView: View {
    let word: Word

    var body: some View {
        HStack {
            Circle()
                .fill(colorForLevel(word.level))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(word.text)
                    .font(.headline)
                if let definition = word.definition {
                    Text(definition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if word.level != .known {
                Text("\(word.level.rawValue)")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
                    .background(colorForLevel(word.level).opacity(0.2), in: Circle())
            } else {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func colorForLevel(_ level: WordLevel) -> Color {
        switch level {
        case .new: AppTheme.newColor
        case .level1: AppTheme.level1Color
        case .level2: AppTheme.level2Color
        case .level3: AppTheme.level3Color
        case .known: AppTheme.knownColor
        }
    }
}
```

- [ ] **Step 2: 实现 VocabularyListView**

`App/lingQ/Vocabulary/VocabularyListView.swift`:
```swift
import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct VocabularyListView: View {
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var filterLevel: WordLevel?
    @State private var searchText = ""

    private var filteredWords: [Word] {
        words.filter { word in
            let matchesLevel = filterLevel == nil || word.level == filterLevel
            let matchesSearch = searchText.isEmpty || word.text.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    var body: some View {
        List {
            // 筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "全部", isSelected: filterLevel == nil) {
                        filterLevel = nil
                    }
                    ForEach([WordLevel.level1, .level2, .level3, .known], id: \.rawValue) { level in
                        FilterChip(
                            title: level == .known ? "✓" : "\(level.rawValue)",
                            isSelected: filterLevel == level
                        ) {
                            filterLevel = level
                        }
                    }
                }
                .padding(.horizontal)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // 单词列表
            ForEach(filteredWords) { word in
                WordCardView(word: word)
            }
            .onDelete { indexSet in
                // 删除逻辑
            }
        }
        .searchable(text: $searchText, prompt: "搜索生词")
        .navigationTitle("生词本")
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accent : Color.secondary.opacity(0.15), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .onTapGesture(perform: onTap)
    }
}
```

- [ ] **Step 3: 更新 ContentView 使用 VocabularyListView**

替换生词本 Tab 的占位文本。

- [ ] **Step 4: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 5: 提交**

```bash
git add -A && git commit -m "feat: add vocabulary list with filtering and search"
```

---

## Task 13: 闪卡复习页面

**Files:**
- Create: `App/lingQ/Review/FlashcardView.swift`
- Create: `App/lingQ/Review/FlashcardReviewView.swift`
- Create: `App/lingQ/Review/ReviewSummaryView.swift`

- [ ] **Step 1: 实现 FlashcardView**

`App/lingQ/Review/FlashcardView.swift`:
```swift
import SwiftUI
import VocabularyKit

struct FlashcardView: View {
    let word: Word
    @State private var isFlipped = false

    var onGrade: (SRSKit.ReviewGrade) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            // 卡片
            ZStack {
                if !isFlipped {
                    // 正面
                    VStack(spacing: 12) {
                        Text(word.text)
                            .font(.largeTitle.bold())
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        Text("点击翻转查看释义")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    // 背面
                    VStack(alignment: .leading, spacing: 12) {
                        Text(word.definition ?? "暂无释义")
                            .font(.title3)
                        if let ctx = word.contextSentence {
                            Divider()
                            Text(ctx)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .onTapGesture { isFlipped.toggle() }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.4), value: isFlipped)

            // 评分按钮（仅翻转后显示）
            if isFlipped {
                HStack(spacing: 12) {
                    GradeButton(title: "重来", color: .red) { onGrade(.again) }
                    GradeButton(title: "困难", color: .orange) { onGrade(.hard) }
                    GradeButton(title: "良好", color: .green) { onGrade(.good) }
                    GradeButton(title: "简单", color: .blue) { onGrade(.easy) }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
    }
}

struct GradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(color)
        }
    }
}

import SRSKit
```

- [ ] **Step 2: 实现 ReviewSummaryView**

`App/lingQ/Review/ReviewSummaryView.swift`:
```swift
import SwiftUI

struct ReviewSummaryView: View {
    let totalReviewed: Int
    let againCount: Int
    let hardCount: Int
    let goodCount: Int
    let easyCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("复习完成")
                .font(.title.bold())

            Text("共复习 \(totalReviewed) 个单词")
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                SummaryRow(title: "重来", count: againCount, color: .red)
                SummaryRow(title: "困难", count: hardCount, color: .orange)
                SummaryRow(title: "良好", count: goodCount, color: .green)
                SummaryRow(title: "简单", count: easyCount, color: .blue)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("完成", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SummaryRow: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .bold()
        }
    }
}
```

- [ ] **Step 3: 实现 FlashcardReviewView**

`App/lingQ/Review/FlashcardReviewView.swift`:
```swift
import SwiftUI
import SwiftData
import VocabularyKit
import SRSKit

struct FlashcardReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reviewWords: [Word] = []
    @State private var currentIndex = 0
    @State private var showSummary = false
    @State private var grades: [ReviewGrade] = []

    private var dueCount: Int { reviewWords.count }

    var body: some View {
        Group {
            if showSummary {
                ReviewSummaryView(
                    totalReviewed: grades.count,
                    againCount: grades.filter { $0 == .again }.count,
                    hardCount: grades.filter { $0 == .hard }.count,
                    goodCount: grades.filter { $0 == .good }.count,
                    easyCount: grades.filter { $0 == .easy }.count,
                    onDone: { showSummary = false; loadWords() }
                )
            } else if reviewWords.isEmpty {
                ContentUnavailableView {
                    Label("暂无待复习单词", systemImage: "sparkles")
                } description: {
                    Text("在精读模式中标记生词后，会按照间隔重复计划出现在这里")
                }
            } else if currentIndex < reviewWords.count {
                VStack {
                    // 进度
                    Text("\(currentIndex + 1) / \(dueCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    FlashcardView(word: reviewWords[currentIndex]) { grade in
                        gradeWord(grade)
                    }
                }
            }
        }
        .navigationTitle("复习")
        .task { loadWords() }
    }

    private func loadWords() {
        let store = VocabularyStore(modelContext: modelContext)
        reviewWords = (try? store.wordsForReview()) ?? []
        currentIndex = 0
        grades = []
        showSummary = false
    }

    private func gradeWord(_ grade: ReviewGrade) {
        let store = VocabularyStore(modelContext: modelContext)
        store.gradeReview(word: reviewWords[currentIndex], grade: grade)
        grades.append(grade)
        currentIndex += 1
        if currentIndex >= reviewWords.count {
            showSummary = true
        }
    }
}
```

- [ ] **Step 4: 更新 ContentView 使用 FlashcardReviewView**

替换复习 Tab 的占位文本。

- [ ] **Step 5: 编译验证**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add flashcard review with SM-2 grading and summary"
```

---

## Task 14: 导航串联和模式切换

**Files:**
- Modify: `App/lingQ/ContentView.swift`
- Modify: `App/lingQ/CourseList/CourseListView.swift`
- Modify: `App/lingQ/IntensiveReading/IntensiveReadingView.swift`

- [ ] **Step 1: 添加 NavigationLink 从课程列表到精读模式**

在 CourseListView 中，NavigationLink 的 destination 设为 IntensiveReadingView。

- [ ] **Step 2: 在精读模式添加切换到泛听模式的按钮**

在 IntensiveReadingView 的 toolbar 中添加按钮，使用 `.fullScreenCover` 呈现 ImmersiveListeningView，共享同一个 AudioPlayer 实例。

- [ ] **Step 3: 编译并在模拟器中运行验证完整导航流程**

```bash
cd App && xcodebuild -scheme lingQ -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

预期：BUILD SUCCEEDED

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: wire up navigation between course list, reading, and immersive modes"
```

---

## Task 15: 最终集成和 UI 精打磨

**Files:**
- 多个已有文件的微调

- [ ] **Step 1: 基于 Figma 设计调整颜色和间距**

使用 `figma:implement-design` skill 从 Figma 获取精确的设计 token，更新 `AppTheme.swift` 中的颜色值和各组件的间距/圆角。

- [ ] **Step 2: 添加 Asset Catalog 中的 Light/Dark 颜色变体**

在 Xcode 的 `Assets.xcassets` 中为每个语义色彩创建 Color Set，配置 Any/Dark Appearance。

- [ ] **Step 3: 运行所有 Package 测试**

```bash
for pkg in SharedModels SRSKit SubtitleKit AudioPlayerKit VocabularyKit; do
  echo "--- $pkg ---"
  cd Packages/$pkg && swift test 2>&1 | tail -3 && cd ../..
done
```

预期：All tests passed（所有 5 个 Package）

- [ ] **Step 4: 在模拟器上完整测试导入→精读→泛听→生词→复习流程**

手动验证：
1. 导入一个 MP3 + SRT 文件对
2. 打开精读模式，播放音频，点击单词查看释义并标记级别
3. 切换到泛听模式，验证歌词同步和 Focused/Ambient 切换
4. 查看生词本，验证已标记的词出现
5. 进入复习，验证闪卡翻转和评分

- [ ] **Step 5: 提交最终版本**

```bash
git add -A && git commit -m "feat: polish UI to match Figma design, integration complete"
```
