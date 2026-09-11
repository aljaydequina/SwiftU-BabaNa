import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    @State private var isSigningIn = false
    @State private var localError = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Spacer()
                        .frame(height: 50)

                    HStack(spacing: 10) {
                        Image(systemName: "bus.fill")
                            .font(.title2)
                            .foregroundStyle(BabaNaTheme.green)

                        Text("BabaNa")
                            .font(.title2.bold())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back")
                            .font(.system(
                                size: 30,
                                weight: .bold
                            ))

                        Text("Log in to continue your trip.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))

                        TextField(
                            "name@example.com",
                            text: $email
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(
                            Color(
                                uiColor:
                                    .secondarySystemGroupedBackground
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))

                        HStack {
                            Group {
                                if showPassword {
                                    TextField(
                                        "Enter password",
                                        text: $password
                                    )
                                } else {
                                    SecureField(
                                        "Enter password",
                                        text: $password
                                    )
                                }
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(
                                    systemName:
                                        showPassword
                                        ? "eye.slash"
                                        : "eye"
                                )
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(
                            Color(
                                uiColor:
                                    .secondarySystemGroupedBackground
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    if !displayedError.isEmpty {
                        Text(displayedError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        login()
                    } label: {
                        Group {
                            if isSigningIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(BabaNaTheme.green)
                        .foregroundStyle(.white)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }
                    .disabled(isSigningIn)

                    HStack(spacing: 5) {
                        Spacer()

                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            RegisterView()
                        } label: {
                            Text("Register")
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    BabaNaTheme.green
                                )
                        }

                        Spacer()
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 22)
            }
            .background(BabaNaTheme.background)
            .navigationBarHidden(true)
        }
    }

    private var displayedError: String {
        if !localError.isEmpty {
            return localError
        }

        return authService.errorMessage
    }

    private func login() {
        localError = ""
        authService.errorMessage = ""

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanEmail.isEmpty,
              !password.isEmpty else {

            localError =
                "Please enter your email and password."

            return
        }

        isSigningIn = true

        authService.login(
            email: cleanEmail,
            password: password
        ) { _ in

            isSigningIn = false
        }
    }
}
