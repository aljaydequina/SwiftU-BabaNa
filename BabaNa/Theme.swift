import SwiftUI
import UIKit

enum BabaNaTheme {
    static let green = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.85, blue: 0.65, alpha: 1)
            : UIColor(red: 0.07, green: 0.36, blue: 0.27, alpha: 1)
    })
    static let forest = Color(red: 0.05, green: 0.25, blue: 0.20)
    static let greenAccent = green
    static let softGreen = green.opacity(0.09)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let muted = Color.secondary
    static let divider = Color.primary.opacity(0.08)
}

struct BabaNaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(BabaNaTheme.forest.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

extension View {
    func babaCard() -> some View {
        padding(18)
            .background(BabaNaTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(BabaNaTheme.divider, lineWidth: 1))
    }
}

struct InfoBanner: View {
    let text: String
    var icon = "info.circle.fill"
    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(BabaNaTheme.softGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LocationPermissionCard: View {
    @EnvironmentObject var locationManager: LocationManager
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(locationManager.permissionTitle, systemImage: "location.circle.fill")
                .font(.headline).foregroundStyle(BabaNaTheme.green)
            Text(locationManager.permissionDetail).font(.subheadline).foregroundStyle(.secondary)
            Button(locationManager.permissionAction) { locationManager.requestPermission() }
                .buttonStyle(.bordered)
            if let error = locationManager.locationError, error != locationManager.permissionDetail {
                Text(error).font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).babaCard()
    }
}
