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
