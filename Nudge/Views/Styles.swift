import SwiftUI

extension ReminderBucket {
    var symbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .thisWeek: "calendar"
        case .later: "hourglass"
        }
    }

    var tint: Color {
        switch self {
        case .today: .accentColor
        case .thisWeek: .indigo
        case .later: .teal
        }
    }
}

/// A springy press for buttons that should feel tactile.
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// A Settings-style rounded square icon.
struct IconBadge: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
