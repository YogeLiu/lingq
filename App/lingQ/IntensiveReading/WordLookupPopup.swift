import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit
import UIKit
import AVFoundation

struct WordLookupPopup: View {
    let word: String
    let contextSentence: String?
    let courseId: UUID?
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var definition: String = ""
    @State private var currentLevel: WordLevel = .new
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(.title.bold())
                    if currentLevel.isLearning {
                        Text("LEVEL \(currentLevel.rawValue) · \(currentLevel.displayName)")
                            .font(.caption.bold())
                            .foregroundStyle(colorForLevel(currentLevel))
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }

            // Definition
            VStack(alignment: .leading, spacing: 4) {
                Text("DEFINITION")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(definition.isEmpty ? "查找中..." : definition)
                    .font(.body)
            }

            // Level buttons
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

                // TTS button
                Button {
                    speakWord()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .frame(width: 36, height: 36)
                }
                .background(Circle().fill(.ultraThinMaterial))
            }

            // Context sentence
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
        synthesizer.speak(utterance)
    }
}
