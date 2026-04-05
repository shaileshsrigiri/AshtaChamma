
import Foundation

struct StartGameUseCase {

    private let repository: GameRepositoryProtocol

    init(repository: GameRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> GameState {
        let players = [
            Player(id: 0, name: "Player 1", colorHex: "e63946"),
            Player(id: 1, name: "Player 2", colorHex: "2196f3"),
            Player(id: 2, name: "Player 3", colorHex: "9c27b0"),
            Player(id: 3, name: "Player 4", colorHex: "ffd700")
        ]

        var tokens: [Int: [Token]] = [:]
        
        players.forEach { player in
            tokens[player.id] = (0..<4).map { _ in
                Token(playerID: player.id)
            }
        }

        let state = GameState(players: players, tokens: tokens, currentPlayerIndex: 0)
        repository.saveGameState(state)
        return state
    }
}
