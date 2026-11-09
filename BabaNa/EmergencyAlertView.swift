import SwiftUI

struct EmergencyAlertView: View {
    let alert: EmergencyTripAlert
    let acknowledge: () -> Void

    var body: some View {
        VStack(spacing: 17) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 9, height: 9)
                    .shadow(color: .red.opacity(0.8), radius: 5)
                Text("BABA NA · TRIP ALERT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                Spacer(minLength: 0)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14))
            }
            .foregroundStyle(.white.opacity(0.9))

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.18))
                    .frame(width: 76, height: 76)
                Circle()
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
                    .frame(width: 76, height: 76)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 33, weight: .semibold))
                    .foregroundStyle(Color(red: 1, green: 0.36, blue: 0.32))
                    .symbolEffect(.pulse)
            }
            .padding(.top, 2)

            VStack(spacing: 9) {
                Text(alert.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(alert.message)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Check your surroundings before getting off.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.top, 3)
            }

            Button(action: acknowledge) {
                HStack(spacing: 9) {
                    Image(systemName: "speaker.slash.fill")
                    Text("STOP ALARM")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(Color(red: 0.87, green: 0.19, blue: 0.22),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(23)
        .background {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay {
                    RoundedRectangle(cornerRadius: 29, style: .continuous)
                        .fill(Color(red: 0.09, green: 0.12, blue: 0.17).opacity(0.65))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 28, y: 15)
        .accessibilityAddTraits(.isModal)
    }
}
