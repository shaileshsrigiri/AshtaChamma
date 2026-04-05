
import Foundation

struct GameState {
    var players: [Player]
    var tokens: [Int:[Token]]
    var currentPlayerIndex: Int
}
