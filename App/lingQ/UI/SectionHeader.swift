import SwiftUI

struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(_ title: String, eyebrow: String? = nil, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.1)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
