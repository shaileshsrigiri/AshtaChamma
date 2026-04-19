
import SwiftUI

// MARK: - Inner loop entry arrows (parity with desktop `ashta_chamma.html`)

private struct InnerLoopArrowShape: Shape {
    var direction: GameEngine.InnerLoopArrowDirection

    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * (x / 20), y: rect.minY + rect.height * (y / 20))
        }
        var p = Path()
        switch direction {
        case .right:
            p.move(to: pt(3, 10)); p.addLine(to: pt(17, 10))
            p.move(to: pt(11, 5)); p.addLine(to: pt(17, 10)); p.addLine(to: pt(11, 15))
        case .left:
            p.move(to: pt(17, 10)); p.addLine(to: pt(3, 10))
            p.move(to: pt(9, 5)); p.addLine(to: pt(3, 10)); p.addLine(to: pt(9, 15))
        case .down:
            p.move(to: pt(10, 3)); p.addLine(to: pt(10, 17))
            p.move(to: pt(5, 11)); p.addLine(to: pt(10, 17)); p.addLine(to: pt(15, 11))
        case .up:
            p.move(to: pt(10, 17)); p.addLine(to: pt(10, 3))
            p.move(to: pt(5, 9)); p.addLine(to: pt(10, 3)); p.addLine(to: pt(15, 9))
        }
        return p
    }
}

/// Corner-to-corner X spanning the cell (same geometry as HTML `crossSVG`).
private struct BoardCellCross: Shape {
    private let padFraction: CGFloat = 0.06

    func path(in rect: CGRect) -> Path {
        let pad = min(rect.width, rect.height) * padFraction
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + pad, y: rect.minY + pad))
        p.addLine(to: CGPoint(x: rect.maxX - pad, y: rect.maxY - pad))
        p.move(to: CGPoint(x: rect.maxX - pad, y: rect.minY + pad))
        p.addLine(to: CGPoint(x: rect.minX + pad, y: rect.maxY - pad))
        return p
    }
}

private struct PulsingTurnGlowToken: View {
    let fill: Color
    let diameter: CGFloat
    let isCurrentPlayer: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 0.6)
            )
            .shadow(color: Color(hex: "f0c040").opacity(isCurrentPlayer ? (pulse ? 0.95 : 0.45) : 0), radius: isCurrentPlayer ? (pulse ? 10 : 4) : 0)
            .shadow(color: Color(hex: "fff8dc").opacity(isCurrentPlayer ? (pulse ? 0.55 : 0.25) : 0), radius: isCurrentPlayer ? (pulse ? 16 : 8) : 0)
            .onAppear {
                guard isCurrentPlayer else { return }
                pulse = false
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onChange(of: isCurrentPlayer) { _, now in
                if !now { pulse = false }
                else {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            }
    }
}

/// Honey–amber “lamplight” backdrop (warm browns and peach, no cool gray).
private struct GameScreenAmbientBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "4a3428"),
                        Color(hex: "2e2218"),
                        Color(hex: "221810")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [
                        Color(hex: "c9a060").opacity(0.38),
                        Color(hex: "8b6238").opacity(0.22),
                        Color(hex: "5c4028").opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.0),
                    startRadius: 30,
                    endRadius: max(w, geo.size.height) * 0.62
                )
                RadialGradient(
                    colors: [
                        Color(hex: "e8b878").opacity(0.18),
                        Color(hex: "a07040").opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.88, y: 0.92),
                    startRadius: 40,
                    endRadius: w * 0.7
                )
                LinearGradient(
                    colors: [
                        Color(hex: "1a1008").opacity(0),
                        Color(hex: "1a0c06").opacity(0.35)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}

struct GameScreen: View {
    @StateObject var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            GameScreenAmbientBackground()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)

                HStack(spacing: 8) {
                    ForEach(viewModel.state.players, id: \.id) { player in
                        PlayerCardFixed(
                            player: player,
                            isCurrent: player.id == viewModel.state.currentPlayerIndex
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)

                BottomControlPanel(viewModel: viewModel)
            }
        }
    }
}

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        let boardSize = UIScreen.main.bounds.width - 8
        let cellSize = (boardSize - 20) / 5.0 // 20 for padding

        VStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { col in
                        let cellIndex = row * 5 + col
                        ZStack(alignment: .center) {
                            // Cell background
                            Rectangle()
                                .fill(getCellColor(row: row, col: col))
                                .border(Color(hex: "a07848").opacity(0.45), width: 1)

                            pathHighlightLayer(cellIndex: cellIndex)

                            cellCrossLayer(cellIndex: cellIndex, cellSize: cellSize)

                            innerLoopEntryArrowLayer(cellIndex: cellIndex, cellSize: cellSize)

                            // Tokens on this cell - show all tokens in a flexible grid
                            ZStack {
                                let tokens = getTokensForCell(row: row, col: col)
                                if tokens.count > 0 {
                                    // Display tokens in a flexible grid (fits up to 9 tokens)
                                    let rows = Int(ceil(Double(tokens.count) / 3.0))
                                    let cols = min(tokens.count, 3)
                                    
                                    VStack(spacing: 1) {
                                        ForEach(0..<rows, id: \.self) { row in
                                            HStack(spacing: 1) {
                                                ForEach(0..<cols, id: \.self) { col in
                                                    let tokenIndex = row * 3 + col
                                                    if tokenIndex < tokens.count,
                                                       let player = viewModel.state.players.first(where: { $0.id == tokens[tokenIndex].playerID }) {
                                                        let token = tokens[tokenIndex]
                                                        let tokenSize = cellSize * 0.25
                                                        let isTheirTurn = token.playerID == viewModel.state.currentPlayerIndex
                                                        PulsingTurnGlowToken(
                                                            fill: Color(hex: player.colorHex),
                                                            diameter: tokenSize,
                                                            isCurrentPlayer: isTheirTurn
                                                        )
                                                        .onTapGesture {
                                                            if let idx = viewModel.state.tokens[token.playerID]?.firstIndex(where: { $0.id == token.id }) {
                                                                viewModel.selectToken(atIndex: idx)
                                                            }
                                                        }
                                                    } else {
                                                        // Empty slot
                                                        Color.clear
                                                            .frame(width: cellSize * 0.25, height: cellSize * 0.25)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(1)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "2a1c14").opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "ffe8b8"),
                            Color(hex: "e8a838"),
                            Color(hex: "c07828")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        )
        .shadow(color: Color(hex: "3d2010").opacity(0.45), radius: 14, x: 0, y: 7)
    }

    private func getCellColor(row: Int, col: Int) -> Color {
        let index = row * 5 + col
        
        if index == 12 { // House — warm olive
            return Color(hex: "5a7038")
        }

        // Safe cells — warm paper
        if [2, 10, 14, 22].contains(index) {
            return Color(hex: "fff6ec")
        }

        // Inner zone — warm sand / sage (no cool mint)
        if [6, 7, 8, 11, 13, 16, 17, 18].contains(index) {
            return Color(hex: "e4dcc8")
        }

        // Start zones — peach cream
        if row == 0 { return Color(hex: "faf0e4") }
        if col == 4 { return Color(hex: "faf0e4") }
        if row == 4 { return Color(hex: "faf0e4") }
        if col == 0 { return Color(hex: "faf0e4") }

        // Outer track — honey tan
        return Color(hex: "ecd4b8")
    }

    private func getTokensForCell(row: Int, col: Int) -> [Token] {
        let cellIndex = row * 5 + col
        var tokens: [Token] = []

        // First, add on-board tokens at this cell
        for (playerId, playerTokens) in viewModel.state.tokens {
            for (tokenIdx, token) in playerTokens.enumerated() {
                // Skip animating token if it's being animated
                if let animating = viewModel.animatingToken,
                   animating.playerID == playerId && animating.tokenIndex == tokenIdx {
                    continue
                }

                // Get the grid cell this token is on using the player's path
                if token.isOnBoard,
                   let gridCell = GameEngine.getCellForToken(playerID: playerId, pathIndex: token.pathIndex),
                   gridCell == cellIndex {
                    tokens.append(token)
                }
            }
        }

        // Handle animating token
        if let animating = viewModel.animatingToken {
            if var animToken = viewModel.state.tokens[animating.playerID]?[animating.tokenIndex] {
                // Interpolate between from and to path indices
                let interpolatedIndex = Double(animating.fromPathIndex) +
                    (Double(animating.toPathIndex - animating.fromPathIndex) * animating.progress)

                let displayIndex = Int(round(interpolatedIndex))

                // Render token at interpolated position
                if let gridCell = GameEngine.getCellForToken(playerID: animating.playerID, pathIndex: displayIndex),
                   gridCell == cellIndex {
                    // Temporarily update token for display
                    animToken.pathIndex = displayIndex
                    animToken.isOnBoard = true
                    tokens.append(animToken)
                }
            }
        }

        // Add finished tokens at the house cell
        if cellIndex == GameEngine.HOUSE {
            for (_, playerTokens) in viewModel.state.tokens {
                let finishedTokens = playerTokens.filter { $0.isFinished }
                tokens.append(contentsOf: finishedTokens)
            }
        }

        // Then, add yard tokens at this cell (if it's a starting cell)
        for (playerId, playerTokens) in viewModel.state.tokens {
            if let startingCell = GameEngine.getCellForToken(playerID: playerId, pathIndex: 0) {
                // If this cell is a player's starting cell, add yard tokens here
                if startingCell == cellIndex {
                    let yardTokens = playerTokens.filter { !$0.isOnBoard && !$0.isFinished }
                    tokens.append(contentsOf: yardTokens)
                }
            }
        }

        return tokens
    }

    private func getPathHighlightType(cellIndex: Int) -> String? {
        guard viewModel.phase == "move" else { return nil }
        guard let moveValue = viewModel.currentMoveValue else { return nil }

        let playerId = viewModel.state.currentPlayerIndex

        for tokenIdx in viewModel.validMoves {
            let pathInfo = viewModel.getPathInfo(playerID: playerId, tokenIndex: tokenIdx, move: moveValue)

            // Check if this is a kill cell
            if let finalCell = pathInfo.finalCell, finalCell == cellIndex, pathInfo.hasKill {
                return "kill"
            }

            // Check if on gradient path (not first cell)
            if pathInfo.pathCells.count > 1 {
                for i in 1..<pathInfo.pathCells.count {
                    if pathInfo.pathCells[i] == cellIndex {
                        return "gradient"
                    }
                }
            }
        }
        return nil
    }

    @ViewBuilder
    private func pathHighlightLayer(cellIndex: Int) -> some View {
        let highlightType = getPathHighlightType(cellIndex: cellIndex)

        if highlightType == "kill" {
            // Glowing red highlight for kill opportunities
            ZStack {
                Circle()
                    .fill(Color(hex: "ff3333").opacity(0.4))
                    .blur(radius: 12)
                Circle()
                    .fill(Color(hex: "ff1111").opacity(0.25))
                    .blur(radius: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if highlightType == "gradient" {
            // Light dots along the path
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func cellCrossLayer(cellIndex: Int, cellSize: CGFloat) -> some View {
        let lineW = max(2, cellSize * (5 / 132))
        if GameEngine.SAFE_CELLS.contains(cellIndex) {
            BoardCellCross()
                .stroke(
                    Color(hex: "2a1800").opacity(0.22),
                    style: StrokeStyle(lineWidth: lineW, lineCap: .round, lineJoin: .round)
                )
                .allowsHitTesting(false)
        } else if cellIndex == GameEngine.HOUSE {
            BoardCellCross()
                .stroke(
                    Color.white.opacity(0.38),
                    style: StrokeStyle(lineWidth: max(2.5, cellSize * (6 / 132)), lineCap: .round, lineJoin: .round)
                )
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func innerLoopEntryArrowLayer(cellIndex: Int, cellSize: CGFloat) -> some View {
        if let entry = GameEngine.innerLoopEntry(cellIndex: cellIndex),
           let player = viewModel.state.players.first(where: { $0.id == entry.playerID }) {
            let hasKill = viewModel.state.tokens[entry.playerID]?.contains { $0.hasCaptured } ?? false
            let arrowFrame = max(16, cellSize * (20 / 132))
            let strokeW = max(1.6, cellSize * (2.8 / 132))
            let edgePad = max(3, cellSize * (6 / 132))
            let align: Alignment = {
                switch entry.direction {
                case .right: return .leading
                case .left: return .trailing
                case .down: return .top
                case .up: return .bottom
                }
            }()
            let pad = EdgeInsets(
                top: entry.direction == .down ? edgePad : 0,
                leading: entry.direction == .right ? edgePad : 0,
                bottom: entry.direction == .up ? edgePad : 0,
                trailing: entry.direction == .left ? edgePad : 0
            )
            InnerLoopArrowShape(direction: entry.direction)
                .stroke(
                    Color(hex: player.colorHex),
                    style: StrokeStyle(lineWidth: strokeW, lineCap: .round, lineJoin: .round)
                )
                .frame(width: arrowFrame, height: arrowFrame)
                .opacity(hasKill ? 1 : 0.25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: align)
                .padding(pad)
                .allowsHitTesting(false)
        }
    }
}

struct PlayerCardFixed: View {
    let player: Player
    var isCurrent: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: player.colorHex))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                .shadow(color: Color(hex: "f0c040").opacity(isCurrent ? 0.75 : 0), radius: isCurrent ? 6 : 0)
                .shadow(color: Color(hex: "fff8dc").opacity(isCurrent ? 0.4 : 0), radius: isCurrent ? 10 : 0)

            Text(player.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "fff5e8"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "fff0dc").opacity(isCurrent ? 0.14 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "e8a848").opacity(isCurrent ? 0.75 : 0.28), lineWidth: isCurrent ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color(hex: "f0c040").opacity(isCurrent ? 0.32 : 0), radius: isCurrent ? 8 : 0)
    }
}

struct BottomControlPanel: View {
    @ObservedObject var viewModel: GameViewModel

    private var canRollCowries: Bool {
        viewModel.phase == "roll" && !viewModel.isAnimating
    }

    private var currentPlayer: Player? {
        viewModel.state.players.first { $0.id == viewModel.state.currentPlayerIndex }
    }

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.phase == "selectMove" {
                VStack(spacing: 6) {
                    Text("SELECT MOVE")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Color(hex: "c89850"))
                    HStack(spacing: 6) {
                        ForEach(viewModel.availableMoveChoices(), id: \.value) { choice in
                            Button(action: { viewModel.selectMoveValue(choice.value) }) {
                                Text(choice.count > 1 ? "\(choice.value)(×\(choice.count))" : "\(choice.value)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "2a1810"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "e8b848"),
                                                Color(hex: "f5d078"),
                                                Color(hex: "d49838")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(hex: "fff2e0").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "e0a860").opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            // One compact row: status (left) + tappable cowries + roll value (right) — saves vertical space vs stacked layout.
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let p = currentPlayer {
                            Circle()
                                .fill(Color(hex: p.colorHex))
                                .frame(width: 10, height: 10)
                        }
                        Text("Player \(viewModel.state.currentPlayerIndex + 1)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "fff2e0"))
                    }
                    Text(viewModel.gameMessage)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: "d8b890"))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { viewModel.rollShells() }) {
                    HStack(spacing: 8) {
                        CowrieShellRow(
                            faceUp: viewModel.cowrieFaceUp,
                            rolling: viewModel.cowriesRolling,
                            shellWidth: 27,
                            shellHeight: 19,
                            shellSpacing: 7
                        )
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(viewModel.rollResult.map(String.init) ?? "—")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(Color(hex: "ffe8a8"))
                                .monospacedDigit()
                            if let result = viewModel.rollResult, result == 8 || result == 4 {
                                Text(result == 8 ? "ASHTA" : "CHAMMA")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(Color(hex: "ffd878"))
                                    .tracking(0.6)
                            }
                        }
                        .frame(minWidth: 34, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        Group {
                            if canRollCowries {
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8b5830").opacity(0.95),
                                        Color(hex: "6b4028").opacity(0.92),
                                        Color(hex: "4a2818").opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color(hex: "fff0e0").opacity(0.07)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(
                                Color(hex: "f0b860").opacity(canRollCowries ? 0.75 : 0.3),
                                lineWidth: canRollCowries ? 1.5 : 1
                            )
                    )
                    .cornerRadius(9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canRollCowries)
                .opacity(canRollCowries ? 1 : 0.9)
                .accessibilityLabel(canRollCowries ? "Roll cowrie shells. Tap to roll." : "Cowrie shells display")
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "3d2a20").opacity(0.92),
                                Color(hex: "2a1c14").opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "d09850").opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color(hex: "3d1808").opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    GameScreen()
}

