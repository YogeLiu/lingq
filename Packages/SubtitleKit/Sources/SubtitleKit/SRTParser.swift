import Foundation
import SharedModels

public enum SRTParser {
    public static func parse(string: String) throws -> [SubtitleCue] {
        let blocks = normalizedSRTContent(string)
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

            let text = normalizedCueText(lines[2...])
            guard !text.isEmpty else { continue }
            cues.append(SubtitleCue(id: index, startTime: start, endTime: end, text: text))
        }
        return cues
    }

    public static func parse(fileURL: URL) throws -> [SubtitleCue] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parse(string: content)
    }

    static func parseTimestampLine(_ line: String) -> (TimeInterval, TimeInterval)? {
        let parts = line.components(separatedBy: "-->")
        guard parts.count == 2,
              let start = parseTimestamp(parts[0].trimmingCharacters(in: .whitespaces)),
              let end = parseTimestamp(parts[1].trimmingCharacters(in: .whitespaces))
        else { return nil }
        return (start, end)
    }

    public static func parseTimestamp(_ string: String) -> TimeInterval? {
        // Format: HH:MM:SS,mmm
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2])
        else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }

    static func normalizedSRTContent(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
    }

    static func normalizedCueText<S: Sequence>(_ lines: S) -> String where S.Element == String {
        lines
            .map(normalizeTextLine)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    static func normalizeTextLine(_ line: String) -> String {
        var normalized = line
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{3000}", with: " ")
            .replacingOccurrences(of: "\t", with: " ")

        normalized = replacing(#"[ ]{2,}"#, in: normalized, with: " ")
        normalized = replacing(#"\s+([,.;:!?，。！？；：])"#, in: normalized, with: "$1")
        normalized = replacing(#"(?<=[\p{Han}])\s+(?=[\p{Han}])"#, in: normalized, with: "")

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func replacing(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}
