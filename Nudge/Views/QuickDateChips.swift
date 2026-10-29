import SwiftUI

struct QuickDateChips: View {
    let selected: QuickDate?
    let onSelect: (QuickDate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickDate.allCases) { option in
                    chip(option)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func chip(_ option: QuickDate) -> some View {
        let isSelected = option == selected
        return Button {
            onSelect(option)
        } label: {
            Label(option.title, systemImage: option.symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background {
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)))
                }
                .symbolEffect(.bounce, value: isSelected)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
