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

@Test func parseNormalizesWhitespaceAndLooseTimestampSpacing() throws {
    let srt = """
    1
    00:00:01,000-->00:00:04,000
    Hello,\t   world !

    2
    00:00:05,000 --> 00:00:08,000
    你 好
    第二　行

    """

    let cues = try SRTParser.parse(string: srt)

    #expect(cues.count == 2)
    #expect(cues[0].text == "Hello, world!")
    #expect(cues[1].text == "你好\n第二行")
}
