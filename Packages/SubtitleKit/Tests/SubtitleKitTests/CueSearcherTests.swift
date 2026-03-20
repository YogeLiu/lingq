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
    #expect(searcher.cue(at: 4.0) == nil)
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
    #expect(searcher.nextCue(after: 8.0)?.id == nil)
}

@Test func findPreviousCue() {
    let cues = [
        SubtitleCue(id: 1, startTime: 0, endTime: 3, text: "First"),
        SubtitleCue(id: 2, startTime: 3, endTime: 6, text: "Second"),
        SubtitleCue(id: 3, startTime: 7, endTime: 10, text: "Third"),
    ]
    let searcher = CueSearcher(cues: cues)

    #expect(searcher.previousCue(before: 4.0)?.id == 1)
    #expect(searcher.previousCue(before: 0.5) == nil)
}
