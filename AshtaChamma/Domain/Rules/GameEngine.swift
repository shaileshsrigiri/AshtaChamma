
import Foundation

struct GameEngine {
    
    // Ashta Chamma board layout - indices on the 5x5 grid
    static let OUTER = [0, 5, 10, 15, 20, 21, 22, 23, 24, 19, 14, 9, 4, 3, 2, 1]
    static let INNER = [6, 7, 8, 13, 18, 17, 16, 11]
    static let HOUSE = 12
    static let SAFE_CELLS = Set([2, 10, 14, 22])
    static let OUTER_LEN = 16

    /// Arrow direction pointing **into** the inner loop from each entry cell (matches `ashta_chamma.html`).
    enum InnerLoopArrowDirection {
        case right, left, up, down
    }

    /// Grid cell → which player may enter the inner path there, and arrow orientation for the UI.
    static func innerLoopEntry(cellIndex: Int) -> (playerID: Int, direction: InnerLoopArrowDirection)? {
        switch cellIndex {
        case 6: return (3, .right)   // P4 — from left (outer 5)
        case 8: return (0, .down)    // P1 — from above (outer 3)
        case 16: return (2, .up)     // P3 — from below (outer 21)
        case 18: return (1, .left)   // P2 — from right (outer 19)
        default: return nil
        }
    }
    
    // Build each player's unique path
    static func buildPlayerPath(outerStart: Int, innerStart: Int) -> [Int] {
        var path: [Int] = []
        
        // Outer ring (16 cells)
        for i in 0..<OUTER_LEN {
            path.append(OUTER[(outerStart + i) % OUTER_LEN])
        }
        
        // Inner ring (8 cells)
        for i in 0..<INNER.count {
            path.append(INNER[(innerStart + i) % INNER.count])
        }
        
        // House (final destination)
        path.append(HOUSE)
        
        return path
    }
    
    // Player paths (position index -> grid cell index)
    static let PLAYER_PATHS = [
        0: buildPlayerPath(outerStart: 14, innerStart: 2),  // Player 1 - enters from top
        1: buildPlayerPath(outerStart: 10, innerStart: 4),  // Player 2 - enters from right
        2: buildPlayerPath(outerStart: 6, innerStart: 6),   // Player 3 - enters from bottom
        3: buildPlayerPath(outerStart: 2, innerStart: 0)    // Player 4 - enters from left
    ]
    
    static func shellValue(from shells: [Bool]) -> Int {
        let up = shells.filter { $0 }.count
        if up == 0 { return 8 }
        if up == 4 { return 4 }
        return up
    }
    
    /// Path index 0..<`OUTER_LEN` = outer ring; `OUTER_LEN`..<24 = inner; 24 = house.
    /// Entering the inner ring (path index ≥ 16) from the outer track or from yard requires capture.
    /// The capture can be by this token OR any other token in the player's group (once any token captures, all can enter).
    static func canMoveToken(token: Token, steps: Int, playerHasAnyCaptured: Bool = false) -> Bool {
        if token.isFinished { return false }
        let newIdx: Int
        if !token.isOnBoard {
            newIdx = steps
        } else {
            newIdx = token.pathIndex + steps
        }
        if newIdx > 24 { return false }
        let onOuterOrYard = !token.isOnBoard || token.pathIndex < OUTER_LEN
        if onOuterOrYard && newIdx >= OUTER_LEN {
            // Can enter inner if this token captured OR any token in the player's group captured
            if !token.hasCaptured && !playerHasAnyCaptured {
                return false
            }
        }
        return true
    }
    
    static func isSafeCell(_ cellIndex: Int) -> Bool {
        return SAFE_CELLS.contains(cellIndex)
    }
    
    static func isHouse(_ cellIndex: Int) -> Bool {
        return cellIndex == HOUSE
    }
    
    static func isBoardPath(_ index: Int) -> Bool {
        return index >= 0 && index <= 24
    }
    
    static func getCellForToken(playerID: Int, pathIndex: Int) -> Int? {
        guard let playerPath = PLAYER_PATHS[playerID] else { return nil }
        guard pathIndex >= 0 && pathIndex < playerPath.count else { return nil }
        return playerPath[pathIndex]
    }

    /// Get all grid cells a token will pass through given a move
    static func getPathCells(playerID: Int, fromPathIndex: Int, steps: Int) -> [Int] {
        guard let playerPath = PLAYER_PATHS[playerID] else { return [] }
        var cells: [Int] = []

        // If token is in yard (fromPathIndex == -1), it enters at pathIndex 0
        let startIdx = max(0, fromPathIndex)
        let endIdx = min(startIdx + steps, 24)

        for i in startIdx...endIdx {
            if i < playerPath.count, let cell = getCellForToken(playerID: playerID, pathIndex: i) {
                cells.append(cell)
            }
        }
        return cells
    }

    /// Get the final grid cell after a move
    static func getFinalCell(playerID: Int, fromPathIndex: Int, steps: Int) -> Int? {
        let newPathIndex = fromPathIndex + steps
        return getCellForToken(playerID: playerID, pathIndex: newPathIndex)
    }
}
