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
