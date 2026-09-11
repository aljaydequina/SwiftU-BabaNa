import Foundation
import FirebaseAuth
import Combine

final class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var errorMessage = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func register(
        email: String,
        password: String,
        completion: @escaping (Bool) -> Void
    ) {
        errorMessage = ""

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        Auth.auth().createUser(
            withEmail: cleanEmail,
            password: password
        ) { [weak self] result, error in

            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                self?.user = result?.user
                completion(true)
            }
        }
    }

    func login(
        email: String,
        password: String,
        completion: @escaping (Bool) -> Void
    ) {
        errorMessage = ""

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        Auth.auth().signIn(
            withEmail: cleanEmail,
            password: password
        ) { [weak self] result, error in

            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                self?.user = result?.user
                completion(true)
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            user = nil
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
