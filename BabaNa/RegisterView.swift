import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isCreatingAccount = false
    @State private var localError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Create account")
                        .font(.system(
                            size: 30,
                            weight: .bold
                        ))

                    Text(
                        "Create your BabaNa account to get started."
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                inputField(
                    title: "Full Name",
                    placeholder: "Your name",
                    text: $fullName
                )

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

                secureInput(
                    title: "Password",
                    placeholder: "At least 6 characters",
                    text: $password
                )

                secureInput(
                    title: "Confirm Password",
                    placeholder: "Repeat password",
                    text: $confirmPassword
                )

                if !displayedError.isEmpty {
                    Text(displayedError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    register()
                } label: {
                    Group {
                        if isCreatingAccount {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
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
                .disabled(isCreatingAccount)

                Text(
                    "Account registration is powered by Firebase Authentication."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(22)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var displayedError: String {
        if !localError.isEmpty {
            return localError
        }

        return authService.errorMessage
    }

    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))

            TextField(
                placeholder,
                text: text
            )
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
    }

    private func secureInput(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))

            SecureField(
                placeholder,
                text: text
            )
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
    }

    private func register() {
        localError = ""
        authService.errorMessage = ""

        let cleanName = fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanName.isEmpty,
              !cleanEmail.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {

            localError = "Please complete all fields."
            return
        }

        guard password.count >= 6 else {
            localError =
                "Password must contain at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            localError = "Passwords do not match."
            return
        }

        isCreatingAccount = true

        authService.register(
            email: cleanEmail,
            password: password
        ) { _ in

            isCreatingAccount = false
        }
    }
}
