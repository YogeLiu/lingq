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
}
