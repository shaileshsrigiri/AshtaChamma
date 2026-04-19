import SwiftUI

struct CreateGameView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var gameCode = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if gameCode.isEmpty {
                    // Create Game Screen
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Create New Game")
                            .font(.system(size: 24, weight: .semibold))

                        Text("Share this game code with your friends and wait for them to join")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Spacer()

                        Button(action: createGame) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            } else {
                                Text("Create Game")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(isLoading)

                        Spacer()
                    }
                    .padding(20)
                } else {
                    // Game Created Screen
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Game Created!")
                            .font(.system(size: 24, weight: .semibold))

                        VStack(spacing: 8) {
                            Text("Share this code with your friends:")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)

                            HStack(spacing: 10) {
                                Text(gameCode)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)

                                Button(action: copyToClipboard) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text("Players waiting: 1/4")
                                    .font(.system(size: 14, weight: .regular))
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                            HStack {
                                Image(systemName: "hourglass.bottomhalf.fill")
                                    .foregroundColor(.orange)
                                Text("Waiting for friends to join...")
                                    .font(.system(size: 14, weight: .regular))
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createGame() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "User not logged in"
            showError = true
            return
        }

        isLoading = true

        FirebaseManager.shared.createGame(players: [userId]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let id):
                    self?.gameCode = id
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = gameCode
    }
}

#Preview {
    CreateGameView()
        .environmentObject(AuthViewModel())
}
