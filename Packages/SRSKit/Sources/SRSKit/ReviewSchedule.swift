public struct ReviewSchedule: Sendable, Equatable {
    public let interval: Int        // days
    public let repetition: Int
    public let easeFactor: Double

    public init(interval: Int, repetition: Int, easeFactor: Double) {
        self.interval = interval
        self.repetition = repetition
        self.easeFactor = easeFactor
    }
}
