
import Foundation

struct Token: Identifiable, Equatable {
    let id: UUID
    let playerID: Int
    var pathIndex: Int = -1           // -1 = yard, 0-15 = outer, 16-23 = inner, 24 = house
    var isOnBoard: Bool = false       // Is this token on the board?
    var onInner: Bool = false         // Has token entered inner ring?
    var isFinished: Bool = false      // Reached house?
    var hasCaptured: Bool = false     // Has this token made a capture?
    
    init(playerID: Int) {
        self.id = UUID()
        self.playerID = playerID
        self.pathIndex = -1
        self.isOnBoard = false
        self.onInner = false
        self.isFinished = false
        self.hasCaptured = false
    }
}
