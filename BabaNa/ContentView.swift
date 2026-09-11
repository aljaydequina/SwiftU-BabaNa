import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {

                ProgressView("Loading...")

            } else if authService.user == nil {

                LoginView()

            } else if !appState.hasFinishedOnboarding {

                OnboardingView()

            } else {

                MainTabView()
            }
        }
    }
}
