
import Foundation
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state: GameState
    @Published var rollResult: Int? = nil
    @Published var gameMessage: String = "Player 1's turn — tap cowries to roll"
    @Published var selectedTokenIndex: Int? = nil
    @Published var validMoves: [Int] = []
    @Published var phase: String = "roll"  // "roll", "selectMove", or "move"
    @Published var isAnimating: Bool = false
    /// Current face of each shell: `true` = slit up (ventral), `false` = dome up (dorsal).
    @Published var cowrieFaceUp: [Bool] = [false, false, false, false]
    @Published var cowriesRolling: Bool = false

    /// Tracks animating token: (playerID, tokenIndex, fromPathIndex, toPathIndex, progress 0-1)
    @Published var animatingToken: (playerID: Int, tokenIndex: Int, fromPathIndex: Int, toPathIndex: Int, progress: Double)? = nil

    private let repository: GameRepositoryProtocol
    private var rollHistory: [Int] = []
    private var movePool: [Int] = []
    private var selectedMove: Int? = nil
    private var animationTimer: Timer? = nil

    /// Public accessor for current move value
    var currentMoveValue: Int? {
        selectedMove ?? movePool.first
    }

    init(repository: GameRepositoryProtocol = InMemoryGameRepository()) {
        self.repository = repository
        let start = StartGameUseCase(repository: repository)
        self.state = start.execute()
    }

    deinit {
        animationTimer?.invalidate()
    }

    // MARK: - Roll the shells
    func rollShells() {
        guard !isAnimating, phase == "roll" else { return }

        isAnimating = true
        Task { await runCowrieAnimationAndResolveRoll() }
    }

    @MainActor
    private func runCowrieAnimationAndResolveRoll() async {
        cowriesRolling = true
        let tickNs: UInt64 = 65_000_000
        for _ in 0..<10 {
            cowrieFaceUp = (0..<4).map { _ in Bool.random() }
            try? await Task.sleep(nanoseconds: tickNs)
        }
        let shells = (0..<4).map { _ in Bool.random() }
        cowrieFaceUp = shells
        cowriesRolling = false

        applyResolvedRoll(shells: shells)
    }

    @MainActor
    private func applyResolvedRoll(shells: [Bool]) {
        let result = GameEngine.shellValue(from: shells)
        rollResult = result
        rollHistory.append(result)
        movePool.append(result)

        gameMessage = "Player \(state.currentPlayerIndex + 1) rolled \(result)"

        if checkThreeInARow() {
            gameMessage = "3 in a row! Player \(state.currentPlayerIndex + 1) loses turn"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.endTurn(bonus: false)
            }
            isAnimating = false
            return
        }

        if result == 8 || result == 4 {
            gameMessage = result == 8 ? "✦ ASHTA - Roll again!" : "✦ CHAMMA - Roll again!"
            isAnimating = false
            return
        }

        if movePool.count > 1 {
            enterSelectMovePhase(continuation: false)
        } else {
            phase = "move"
            selectedMove = movePool.first
            updateValidMoves()
            applyPhaseAfterMoveOptionsSet()
        }
        isAnimating = false
    }

    private func enterSelectMovePhase(continuation: Bool) {
        phase = "selectMove"
        selectedMove = nil
        updateValidMoves()
        if availableMoveChoices().isEmpty {
            gameMessage = continuation
                ? "No legal moves left. Turn passes."
                : "No legal moves with [\(movePool.map(String.init).joined(separator: ", "))]. Turn passes."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.rollHistory = []
                self.endTurn(bonus: false)
            }
        } else {
            gameMessage = continuation
                ? "Remaining: [\(movePool.map(String.init).joined(separator: ", "))] — choose a move"
                : "Choose a move from [\(movePool.map(String.init).joined(separator: ", "))]"
        }
    }

    /// Call after `selectedMove` is set and `updateValidMoves()` has run.
    private func applyPhaseAfterMoveOptionsSet() {
        guard let move = selectedMove else { return }
        if validMoves.isEmpty {
            gameMessage = "No legal moves with \(move). Turn passes."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.endTurn(bonus: false)
            }
            return
        }
        gameMessage = "Select a token to move by \(move) steps"
    }

    /// User picked one value from the move pool (when pool has more than one number).
    func selectMoveValue(_ value: Int) {
        guard phase == "selectMove", movePool.contains(value), !isAnimating else { return }
        selectedMove = value
        phase = "move"
        updateValidMoves()
        applyPhaseAfterMoveOptionsSet()
    }

    // MARK: - Select and move token
    func selectToken(atIndex index: Int) {
        guard phase == "move", !isAnimating else { 
            print("DEBUG: Cannot select - phase=\(phase), animating=\(isAnimating)")
            return 
        }
        guard let move = selectedMove else {
            print("DEBUG: No selected move")
            return 
        }
        guard let playerTokens = state.tokens[state.currentPlayerIndex] else { 
            print("DEBUG: No player tokens")
            return 
        }
        
        let token = playerTokens[index]

        // Validate move
        guard validMoves.contains(index) else {
            print("DEBUG: Token not in valid moves. Valid: \(validMoves), Index: \(index)")
            return
        }

        let hasAnyCaptured = playerTokens.contains { $0.hasCaptured }
        guard GameEngine.canMoveToken(token: token, steps: move, playerHasAnyCaptured: hasAnyCaptured) else {
            gameMessage = "Invalid move!"
            return
        }

        print("DEBUG: Moving token \(index) by \(move)")
        selectedTokenIndex = index
        performMove(tokenIndex: index, move: move)
    }

    private func performMove(tokenIndex: Int, move: Int) {
        guard let playerTokens = state.tokens[state.currentPlayerIndex] else { return }
        let token = playerTokens[tokenIndex]

        isAnimating = true

        let fromPathIndex = token.isOnBoard ? token.pathIndex : -1
        let toPathIndex = token.isOnBoard ? (token.pathIndex + move) : move

        // Start animation
        selectedTokenIndex = tokenIndex
        animatingToken = (state.currentPlayerIndex, tokenIndex, fromPathIndex, toPathIndex, 0)

        // Animate with duration proportional to distance (base 0.3s + 0.06s per step)
        let distance = abs(toPathIndex - fromPathIndex)
        let animationDuration = 0.7 + (Double(distance) * 0.2)
        let startTime = Date()

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / animationDuration, 1.0)

                self.animatingToken?.progress = progress

                if progress >= 1.0 {
                    self.animationTimer?.invalidate()
                    self.completeAnimatedMove(tokenIndex: tokenIndex, move: move)
                }
            }
        }
    }

    private func completeAnimatedMove(tokenIndex: Int, move: Int) {
        guard var playerTokens = state.tokens[state.currentPlayerIndex] else { return }
        var token = playerTokens[tokenIndex]

        // Enter board if in yard
        if !token.isOnBoard {
            token.isOnBoard = true
            token.pathIndex = move
            gameMessage = "Token enters board and moves \(move) steps!"
        } else {
            token.pathIndex += move
        }
        token.onInner = token.pathIndex >= GameEngine.OUTER_LEN && token.pathIndex < 24

        playerTokens[tokenIndex] = token
        state.tokens[state.currentPlayerIndex] = playerTokens

        // Clear animation state
        animatingToken = nil
        selectedTokenIndex = nil

        // Remove used move
        if let idx = movePool.firstIndex(of: move) {
            movePool.remove(at: idx)
        }

        selectedMove = nil
        phase = "roll"  // Reset to roll phase

        // Check end conditions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.checkMoveCompletion(playerID: self.state.currentPlayerIndex, tokenIndex: tokenIndex)
        }
    }

    /// Check if a final cell has an opponent token (capture opportunity)
    /// Returns false if the cell is safe (can't be captured)
    func hasOpponentTokenAtCell(_ cellIndex: Int, playerID: Int) -> Bool {
        // Can't capture on safe cells or house
        if GameEngine.isSafeCell(cellIndex) || GameEngine.isHouse(cellIndex) {
            return false
        }

        for opID in 0..<4 {
            guard opID != playerID else { continue }
            guard let opTokens = state.tokens[opID] else { continue }

            for opToken in opTokens {
                guard opToken.isOnBoard, !opToken.isFinished else { continue }
                if let opGridCell = GameEngine.getCellForToken(playerID: opID, pathIndex: opToken.pathIndex),
                   opGridCell == cellIndex {
                    return true
                }
            }
        }
        return false
    }

    /// Get all path cells and final cell for a token with a given move
    func getPathInfo(playerID: Int, tokenIndex: Int, move: Int) -> (pathCells: [Int], finalCell: Int?, hasKill: Bool) {
        guard let tokens = state.tokens[playerID], tokenIndex < tokens.count else {
            return ([], nil, false)
        }
        let token = tokens[tokenIndex]
        let fromPathIndex = token.isOnBoard ? token.pathIndex : -1
        let pathCells = GameEngine.getPathCells(playerID: playerID, fromPathIndex: fromPathIndex, steps: move)
        let finalCell = pathCells.last
        let hasKill = finalCell.map { hasOpponentTokenAtCell($0, playerID: playerID) } ?? false
        return (pathCells, finalCell, hasKill)
    }

    private func checkMoveCompletion(playerID: Int, tokenIndex: Int) {
        guard let playerTokens = state.tokens[playerID] else {
            isAnimating = false
            return
        }
        let token = playerTokens[tokenIndex]
        var shouldCapture = false
        
        // Check if reached house
        if token.pathIndex >= 24 {
            var tokens = playerTokens
            tokens[tokenIndex].isFinished = true
            tokens[tokenIndex].isOnBoard = false
            state.tokens[playerID] = tokens
            gameMessage = "Token reached the House!"
            
            // Check if all tokens finished
            if tokens.allSatisfy({ $0.isFinished }) {
                gameMessage = "Player \(playerID + 1) WINS!"
                phase = "finished"
                isAnimating = false
                return
            }
        } else {
            // Check for captures on non-safe cells
            if let gridCell = GameEngine.getCellForToken(playerID: playerID, pathIndex: token.pathIndex) {
                if !GameEngine.isSafeCell(gridCell) && gridCell != GameEngine.HOUSE {
                    shouldCapture = checkForCapture(playerID: playerID, gridCell: gridCell, tokenIndex: tokenIndex)
                }
            }
        }
        
        // Handle move completion
        if shouldCapture {
            gameMessage = "Captured! Roll again!"
            phase = "roll"
            rollResult = nil
        } else if movePool.isEmpty {
            rollHistory = []
            endTurn(bonus: false)
        } else {
            if movePool.count > 1 {
                enterSelectMovePhase(continuation: true)
            } else {
                selectedMove = movePool.first
                phase = "move"
                updateValidMoves()
                if validMoves.isEmpty {
                    gameMessage = "No legal moves left. Turn passes."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        self.rollHistory = []
                        self.endTurn(bonus: false)
                    }
                } else {
                    gameMessage = "Remaining move: \(movePool[0]) — select a token"
                }
            }
        }
        
        isAnimating = false
    }

    private func checkForCapture(playerID: Int, gridCell: Int, tokenIndex: Int) -> Bool {
        // Look for opponent tokens on this cell
        for opID in 0..<4 {
            guard opID != playerID else { continue }
            guard var opTokens = state.tokens[opID] else { continue }
            
            for (opTI, opToken) in opTokens.enumerated() {
                guard opToken.isOnBoard, !opToken.isFinished else { continue }
                
                if let opGridCell = GameEngine.getCellForToken(playerID: opID, pathIndex: opToken.pathIndex),
                   opGridCell == gridCell {
                    // Capture this token
                    opTokens[opTI].isOnBoard = false
                    opTokens[opTI].pathIndex = -1
                    opTokens[opTI].onInner = false
                    state.tokens[opID] = opTokens
                    
                    // Mark captor
                    var myTokens = state.tokens[playerID]!
                    myTokens[tokenIndex].hasCaptured = true
                    state.tokens[playerID] = myTokens
                    
                    gameMessage = "Player \(playerID + 1) captured Player \(opID + 1)'s token!"
                    return true
                }
            }
        }
        return false
    }

    private func checkThreeInARow() -> Bool {
        guard rollHistory.count >= 3 else { return false }
        let last3 = Array(rollHistory.suffix(3))
        return last3.allSatisfy({ $0 == last3[0] }) && (last3[0] == 8 || last3[0] == 4)
    }

    private func updateValidMoves() {
        if phase == "selectMove" {
            validMoves = []
            return
        }
        guard let move = selectedMove ?? movePool.first else {
            validMoves = []
            return
        }
        let pid = state.currentPlayerIndex
        let playerTokens = state.tokens[pid] ?? []
        let hasAnyCaptured = playerTokens.contains { $0.hasCaptured }
        validMoves = playerTokens.enumerated().compactMap { index, token in
            GameEngine.canMoveToken(token: token, steps: move, playerHasAnyCaptured: hasAnyCaptured) ? index : nil
        }
    }

    /// Unique move values still in the pool that at least one token can use (for the move picker UI).
    func availableMoveChoices() -> [(value: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for m in movePool { counts[m, default: 0] += 1 }
        let pid = state.currentPlayerIndex
        let playerTokens = state.tokens[pid] ?? []
        let hasAnyCaptured = playerTokens.contains { $0.hasCaptured }
        return counts.keys.sorted().compactMap { value in
            let anyLegal = playerTokens.contains { token in
                !token.isFinished && GameEngine.canMoveToken(token: token, steps: value, playerHasAnyCaptured: hasAnyCaptured)
            }
            guard anyLegal else { return nil }
            return (value, counts[value]!)
        }
    }

    private func endTurn(bonus: Bool) {
        rollResult = nil
        rollHistory = []
        movePool = []
        selectedMove = nil
        selectedTokenIndex = nil
        validMoves = []
        phase = "roll"
        
        if !bonus {
            state.currentPlayerIndex = (state.currentPlayerIndex + 1) % 4
        }
        
        gameMessage = "Player \(state.currentPlayerIndex + 1)'s turn — tap cowries to roll"
    }
}
