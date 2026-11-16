import SwiftUI

/// On-screen trip reminder. Shown while the looping alarm sound plays;
/// tapping the button acknowledges the reminder and stops the alarm.
/// Styled as a calm reminder card (app greens), not a red emergency alert.
struct EmergencyAlertView: View {
    let alert: EmergencyTripAlert
    let acknowledge: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripple = false

    private var isArrival: Bool { alert.id.hasSuffix("-arrival") }

    private var hint: (icon: String, text: String) {
        isArrival
            ? ("figure.walk.departure", "Ihanda na ang gamit mo at tingnan ang paligid bago bumaba.")
            : ("bag.fill", "Malapit na ang stop mo. Ihanda na ang gamit mo.")
    }

    var body: some View {
        VStack(spacing: 18) {
            header

            bell
                .padding(.top, 4)

            VStack(spacing: 8) {
                Text(alert.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(alert.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(hint.text, systemImage: hint.icon)
                .font(.footnote)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(BabaNaTheme.softGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: acknowledge) {
                Label("Okay, stop alarm", systemImage: "checkmark")
            }
            .buttonStyle(BabaNaPrimaryButtonStyle())
            .accessibilityHint("Stops the reminder sound and closes this reminder.")
        }
        .padding(22)
        .background(BabaNaTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(BabaNaTheme.green.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear { ripple = true }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("TRIP REMINDER", systemImage: "bus.fill")
                .font(.caption2.bold())
                .tracking(1.2)
                .foregroundStyle(BabaNaTheme.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BabaNaTheme.softGreen, in: Capsule())

            Spacer(minLength: 0)

            // Small cue that the alarm sound is still playing.
            HStack(spacing: 5) {
                Image(systemName: "speaker.wave.2.fill")
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: !reduceMotion)
                Text("Ringing")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Alarm is ringing")
        }
    }

    private var bell: some View {
        ZStack {
            // Soft expanding ring, like a gentle chime rather than a siren.
            Circle()
                .stroke(BabaNaTheme.green.opacity(0.25), lineWidth: 2)
                .frame(width: 84, height: 84)
                .scaleEffect(ripple && !reduceMotion ? 1.35 : 1)
                .opacity(ripple && !reduceMotion ? 0 : 1)
                .animation(reduceMotion ? nil : .easeOut(duration: 1.6).repeatForever(autoreverses: false),
                           value: ripple)

            Circle()
                .fill(BabaNaTheme.softGreen)
                .frame(width: 84, height: 84)

            Image(systemName: "bell.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(BabaNaTheme.green)
                .symbolEffect(.wiggle, options: .repeat(.continuous), isActive: !reduceMotion)
        }
        .accessibilityHidden(true)
    }
}
