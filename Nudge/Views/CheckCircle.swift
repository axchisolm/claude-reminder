import SwiftUI

/// The completion checkbox: fills with a springy pop and a little ripple.
struct CheckCircle: View {
    var isOn: Bool
    var tint: Color
    var action: () -> Void

    @State private var ripples = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(isOn ? tint : Color(uiColor: .tertiaryLabel), lineWidth: 1.75)
                Circle()
                    .fill(tint.gradient)
                    .padding(3.5)
                    .scaleEffect(isOn ? 1 : 0.2)
                    .opacity(isOn ? 1 : 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .scaleEffect(isOn ? 1 : 0.2)
                    .opacity(isOn ? 1 : 0)
                Circle()
                    .stroke(tint, lineWidth: 2)
                    .keyframeAnimator(initialValue: Ripple(), trigger: ripples) { ring, ripple in
                        ring.scaleEffect(ripple.scale).opacity(ripple.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(1, duration: 0)
                            CubicKeyframe(2, duration: 0.45)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0.6, duration: 0)
                            CubicKeyframe(0, duration: 0.45)
                        }
                    }
            }
            .frame(width: 22, height: 22)
            .contentShape(Circle().inset(by: -10))
        }
        .buttonStyle(.borderless)
        .onChange(of: isOn) { _, on in
            if on { ripples += 1 }
        }
        .accessibilityLabel(isOn ? "Completed" : "Mark as completed")
    }

    private struct Ripple {
        var scale: CGFloat = 1
        var opacity: Double = 0
    }
}

#Preview {
    @Previewable @State var on = false
    CheckCircle(isOn: on, tint: .accentColor) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { on.toggle() }
    }
    .scaleEffect(3)
}
