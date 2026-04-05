
import Foundation

final class InMemoryGameRepository: GameRepositoryProtocol {

    private var state: GameState = GameState(players: [], tokens: [:], currentPlayerIndex: 0)

    func loadGameState() -> GameState {
        state
    }

    func saveGameState(_ state: GameState) {
        self.state = state
    }
}
