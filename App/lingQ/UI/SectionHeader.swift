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
        VStack(alignment: .leading, spacing: 4) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
            }

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}
