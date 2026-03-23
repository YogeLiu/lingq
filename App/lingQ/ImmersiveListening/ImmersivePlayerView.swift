import SwiftUI
import AudioPlayerKit

struct ImmersivePlayerView: View {
    @Bindable var player: AudioPlayer
    @Binding var isABRepeatActive: Bool

    let availableSpeeds: [Float]
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkipBackward: () -> Void
    let onSkipForward: () -> Void
    let onToggleABRepeat: () -> Void

    var body: some View {
        PlaybackControlCard(
            player: player,
            availableSpeeds: availableSpeeds,
            isLoopActive: isABRepeatActive,
            onSubtitleTap: nil,
            onPrevious: onPrevious,
            onNext: onNext,
            onSkipBackward: onSkipBackward,
            onSkipForward: onSkipForward,
            onToggleLoop: onToggleABRepeat
        )
        .padding()
    }
}
