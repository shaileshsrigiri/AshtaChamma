import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User? = nil
    @Published var currentUserId: String? = nil
    @Published var currentUsername: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading = false

    init() {
        // Check if user is already logged in
        if let user = Auth.auth().currentUser {
            self.currentUserId = user.uid
            self.isLoggedIn = true
            self.currentUser = user
            loadUserProfile(uid: user.uid)
        }
    }

    func signUp(email: String, password: String, username: String) {
        isLoading = true
        errorMessage = nil

        FirebaseManager.shared.signUp(email: email, password: password, username: username) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let userId):
                    self?.currentUserId = userId
                    self?.currentUser = Auth.auth().currentUser
                    self?.currentUsername = username
                    self?.isLoggedIn = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        FirebaseManager.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let userId):
                    self?.currentUserId = userId
                    self?.currentUser = Auth.auth().currentUser
                    self?.isLoggedIn = true
                    self?.loadUserProfile(uid: userId)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logout() {
        do {
            try FirebaseManager.shared.logout()
            self.isLoggedIn = false
            self.currentUserId = nil
            self.currentUser = nil
            self.currentUsername = nil
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func loadUserProfile(uid: String) {
        FirebaseManager.shared.getUserProfile(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userData):
                    self?.currentUsername = userData["username"] as? String
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
