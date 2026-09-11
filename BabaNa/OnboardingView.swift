import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var page = 0

    var body: some View {
        Group {
            if page == 0 {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        page = 1
                    }
                }
            } else {
                PermissionView {
                    appState.hasFinishedOnboarding = true
                }
            }
        }
    }
}

private struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BabaNaTheme.green
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "bus.fill")
                        .font(.title3)
                        .foregroundStyle(.white)

                    Text("BabaNa")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.top, 16)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.08))
                        .frame(height: 250)

                    VStack(spacing: 18) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 84))
                            .foregroundStyle(.white.opacity(0.16))

                        Image(systemName: "bus.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                Text("Relax while you ride.")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(.white)

                Text("Set your destination and get reminded before your stop.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.top, 8)

                Button(action: onContinue) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white)
                        .foregroundStyle(BabaNaTheme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 26)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
        }
    }
}

private struct PermissionView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer(minLength: 28)

            Image(systemName: "location.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(BabaNaTheme.greenAccent)

            Text("Enable trip alerts")
                .font(.largeTitle.bold())

            Text("BabaNa needs location and notification access while a trip is active.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                permissionRow(
                    icon: "location.fill",
                    title: "Location",
                    subtitle: locationText,
                    action: { locationManager.requestPermission() }
                )

                Divider()

                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: notificationManager.isAuthorized ? "Allowed" : "Tap to allow",
                    action: { notificationManager.requestPermission() }
                )
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(BabaNaTheme.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(22)
        .background(BabaNaTheme.background.ignoresSafeArea())
    }

    private func permissionRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 28)
                    .foregroundStyle(BabaNaTheme.green)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var locationText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Allowed"
        case .denied, .restricted:
            return "Permission denied"
        default:
            return "Tap to allow"
        }
    }
}
