
import Foundation

protocol GameRepositoryProtocol {
    func loadGameState() -> GameState
    func saveGameState(_ state: GameState)
}
