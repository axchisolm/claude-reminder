import SwiftUI

struct SectionHeader: View {
    let bucket: ReminderBucket
    let count: Int
    let isExpanded: Bool
    /// `nil` for sections that can't collapse.
    let toggle: (() -> Void)?

    var body: some View {
        if let toggle {
            Button(action: toggle) { content }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isExpanded)
                .accessibilityHint(isExpanded ? "Collapses the section" : "Expands the section")
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 8) {
            Image(systemName: bucket.symbol)
                .foregroundStyle(bucket.tint)
                .symbolEffect(.bounce, value: count)

            Text(bucket.title)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            if count > 0 {
                Text("\(count)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(bucket.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(bucket.tint.opacity(0.15), in: Capsule())
                    .contentTransition(.numericText(value: Double(count)))
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            if toggle != nil {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .textCase(nil)
        .contentShape(Rectangle())
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}
