import SwiftUI

struct GameLobbyView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var gameCode = ""
    @State private var showCreateGame = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(authViewModel.currentUsername ?? "Player")")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Ready to play?")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { authViewModel.logout() }) {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Main Content
            VStack(spacing: 20) {
                // Create Game Option
                Button(action: { showCreateGame = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)

                        Text("Create Game")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Start a new game and invite your friends")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Join Game Option
                VStack(spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)

                    Text("Join Game")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)

                    Text("Enter game code from your friend")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 10) {
                        TextField("Game Code", text: $gameCode)
                            .keyboardType(.default)
                            .textInputAutocapitalization(.characters)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)

                        Button(action: joinGame) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(gameCode.isEmpty || isLoading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()
            }
            .padding(.horizontal)

            Spacer()
        }
        .sheet(isPresented: $showCreateGame) {
            CreateGameView()
                .environmentObject(authViewModel)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func joinGame() {
        guard !gameCode.isEmpty else { return }

        isLoading = true

        guard let userId = authViewModel.currentUserId else {
            errorMessage = "User not logged in"
            showErrorAlert = true
            isLoading = false
            return
        }

        FirebaseManager.shared.joinGame(gameId: gameCode, playerId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    // Navigate to game
                    self?.gameCode = ""
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    GameLobbyView()
        .environmentObject(AuthViewModel())
}
