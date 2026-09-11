import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                TripsView()
            }
            .tabItem {
                Label("Trips", systemImage: "clock.fill")
            }

            NavigationStack {
                SavedStopsView()
            }
            .tabItem {
                Label("Saved", systemImage: "heart.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(BabaNaTheme.green)
    }
}
