//
//  AshtaChammaTests.swift
//  AshtaChammaTests
//
//  Created by Shailesh Srigiri on 4/18/26.
//

import XCTest
@testable import AshtaChamma

@MainActor
final class AshtaChammaTests: XCTestCase {

    var viewModel: GameViewModel!

    override func setUpWithError() throws {
        super.setUp()
        viewModel = GameViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Shell Value Tests

    func testShellValue_AllUp_ReturnsFour() throws {
        let shells = [true, true, true, true]
        XCTAssertEqual(GameEngine.shellValue(from: shells), 4, "4 shells up should return 4 (CHAMMA)")
    }

    func testShellValue_AllDown_ReturnsEight() throws {
        let shells = [false, false, false, false]
        XCTAssertEqual(GameEngine.shellValue(from: shells), 8, "0 shells up should return 8 (ASHTA)")
    }

    func testShellValue_TwoUp_ReturnsTwo() throws {
        let shells = [true, true, false, false]
        XCTAssertEqual(GameEngine.shellValue(from: shells), 2, "2 shells up should return 2")
    }

    func testShellValue_ThreeUp_ReturnsThree() throws {
        let shells = [true, true, true, false]
        XCTAssertEqual(GameEngine.shellValue(from: shells), 3, "3 shells up should return 3")
    }

    func testShellValue_OneUp_ReturnsOne() throws {
        let shells = [true, false, false, false]
        XCTAssertEqual(GameEngine.shellValue(from: shells), 1, "1 shell up should return 1")
    }

    // MARK: - Token Movement Validation Tests

    func testCanMoveToken_OnBoardValidDistance() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 5
        token.hasCaptured = false

        XCTAssertTrue(GameEngine.canMoveToken(token: token, steps: 2), "Should move 2 steps on outer track")
    }

    func testCanMoveToken_OutOfBounds() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 23

        XCTAssertFalse(GameEngine.canMoveToken(token: token, steps: 5), "Moving 23+5=28 exceeds house (24)")
    }

    func testCanMoveToken_EnterInnerWithoutCapture_ShouldFail() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 14  // Outer track
        token.hasCaptured = false

        XCTAssertFalse(GameEngine.canMoveToken(token: token, steps: 4), "Cannot enter inner (14+4=18) without capture")
    }

    func testCanMoveToken_EnterInnerWithCapture_ShouldSucceed() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 14
        token.hasCaptured = true

        XCTAssertTrue(GameEngine.canMoveToken(token: token, steps: 4), "Can enter inner with capture")
    }

    func testCanMoveToken_FromYard() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = false
        token.pathIndex = -1

        XCTAssertTrue(GameEngine.canMoveToken(token: token, steps: 3), "Can enter board from yard")
    }

    func testCanMoveToken_Finished_CannotMove() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 20
        token.isFinished = true

        XCTAssertFalse(GameEngine.canMoveToken(token: token, steps: 2), "Finished token cannot move")
    }

    // MARK: - Safe Cell Tests

    func testSafeCells_AreCorrect() throws {
        XCTAssertTrue(GameEngine.isSafeCell(2))
        XCTAssertTrue(GameEngine.isSafeCell(10))
        XCTAssertTrue(GameEngine.isSafeCell(14))
        XCTAssertTrue(GameEngine.isSafeCell(22))
    }

    func testSafeCells_AreIncorrect() throws {
        XCTAssertFalse(GameEngine.isSafeCell(0))
        XCTAssertFalse(GameEngine.isSafeCell(5))
        XCTAssertFalse(GameEngine.isSafeCell(12)) // House is not safe
    }

    // MARK: - House Cell Tests

    func testHouseCell_IsCorrect() throws {
        XCTAssertTrue(GameEngine.isHouse(12))
    }

    func testHouseCell_IsIncorrect() throws {
        XCTAssertFalse(GameEngine.isHouse(2))
        XCTAssertFalse(GameEngine.isHouse(24))
    }

    // MARK: - Path Navigation Tests

    func testGetCellForToken_ValidPathIndex() throws {
        if let cell = GameEngine.getCellForToken(playerID: 0, pathIndex: 0) {
            XCTAssertGreaterThanOrEqual(cell, 0)
            XCTAssertLessThanOrEqual(cell, 24)
        }
    }

    func testGetCellForToken_InvalidPathIndex() throws {
        let cell = GameEngine.getCellForToken(playerID: 0, pathIndex: 100)
        XCTAssertNil(cell, "Path index 100 should be out of bounds")
    }

    func testGetCellForToken_HousePosition() throws {
        if let cell = GameEngine.getCellForToken(playerID: 0, pathIndex: 24) {
            XCTAssertEqual(cell, GameEngine.HOUSE, "Path index 24 should be house")
        }
    }

    // MARK: - Path Cells Calculation Tests

    func testGetPathCells_ValidRange() throws {
        let cells = GameEngine.getPathCells(playerID: 0, fromPathIndex: 0, steps: 3)
        XCTAssertEqual(cells.count, 4, "Moving 3 steps from 0 should include 4 cells")
    }

    func testGetPathCells_LongMove() throws {
        let cells = GameEngine.getPathCells(playerID: 0, fromPathIndex: 20, steps: 4)
        XCTAssertGreaterThan(cells.count, 0)
        XCTAssertLessThanOrEqual(cells.count, 5)
    }

    // MARK: - Inner Loop Entry Tests

    func testInnerLoopEntry_Player0() throws {
        if let entry = GameEngine.innerLoopEntry(cellIndex: 8) {
            XCTAssertEqual(entry.playerID, 0, "Cell 8 is player 0's entry point")
        }
    }

    func testInnerLoopEntry_Player1() throws {
        if let entry = GameEngine.innerLoopEntry(cellIndex: 18) {
            XCTAssertEqual(entry.playerID, 1, "Cell 18 is player 1's entry point")
        }
    }

    func testInnerLoopEntry_InvalidCell() throws {
        let entry = GameEngine.innerLoopEntry(cellIndex: 0)
        XCTAssertNil(entry, "Cell 0 is not an entry point")
    }


    // MARK: - Game State Tests

    func testInitialGameState_FourPlayers() throws {
        XCTAssertEqual(viewModel.state.currentPlayerIndex, 0)
        XCTAssertEqual(viewModel.state.players.count, 4)
    }

    func testInitialGameState_AllTokensInYard() throws {
        for playerId in 0..<4 {
            guard let tokens = viewModel.state.tokens[playerId] else {
                XCTFail("Player \(playerId) should have tokens")
                return
            }
            XCTAssertEqual(tokens.count, 4, "Each player should have 4 tokens")
            for token in tokens {
                XCTAssertFalse(token.isOnBoard, "Tokens start in yard")
                XCTAssertFalse(token.isFinished)
            }
        }
    }

    func testGamePhase_StartsWithRoll() throws {
        XCTAssertEqual(viewModel.phase, "roll", "Game should start in roll phase")
    }

    // MARK: - Inner Loop Entry Rule Tests (KEY FEATURE)

    func testEnterInnerLoop_WithoutAnyCapture_ShouldFail() throws {
        // Set up: no token has captured
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 14
        token.hasCaptured = false

        viewModel.state.tokens[0] = [token, Token(playerID: 0), Token(playerID: 0), Token(playerID: 0)]

        // Attempting to enter inner loop without capture should fail
        let canMove = GameEngine.canMoveToken(token: token, steps: 4)
        XCTAssertFalse(canMove, "Cannot enter inner loop without any token capturing first")
    }

    func testEnterInnerLoop_WithAnyCaptured_AllTokensCanEnter() throws {
        // Set up: one token has captured, others haven't
        var token1 = Token(playerID: 0)
        token1.isOnBoard = true
        token1.pathIndex = 14
        token1.hasCaptured = false

        var token2 = Token(playerID: 0)
        token2.isOnBoard = true
        token2.pathIndex = 5
        token2.hasCaptured = true  // This token captured!

        var token3 = Token(playerID: 0)
        token3.isOnBoard = false

        var token4 = Token(playerID: 0)
        token4.isOnBoard = false

        viewModel.state.tokens[0] = [token1, token2, token3, token4]

        // Now token1 should be able to enter inner loop because ANY token has captured
        let canMove = GameEngine.canMoveToken(token: token1, steps: 4, playerHasAnyCaptured: true)
        XCTAssertTrue(canMove, "After ANY token captures, ALL tokens can enter inner loop")
    }

    // MARK: - Opponent Detection Tests

    func testHasOpponentTokenAtCell_WithOpponent() throws {
        var opponentToken = Token(playerID: 1)
        opponentToken.isOnBoard = true
        opponentToken.pathIndex = 7  // Player 1's pathIndex 7 maps to cell 5

        viewModel.state.tokens[1] = [opponentToken, Token(playerID: 1), Token(playerID: 1), Token(playerID: 1)]

        let hasOpponent = viewModel.hasOpponentTokenAtCell(5, playerID: 0)
        XCTAssertTrue(hasOpponent, "Should detect opponent at cell 5")
    }

    func testHasOpponentTokenAtCell_SafeCellProtected() throws {
        var opponentToken = Token(playerID: 1)
        opponentToken.isOnBoard = true
        opponentToken.pathIndex = 0

        viewModel.state.tokens[1] = [opponentToken, Token(playerID: 1), Token(playerID: 1), Token(playerID: 1)]

        // Safe cells protect tokens from capture
        let hasOpponent = viewModel.hasOpponentTokenAtCell(2, playerID: 0)
        XCTAssertFalse(hasOpponent, "Tokens on safe cells cannot be captured")
    }

    func testHasOpponentTokenAtCell_HouseProtected() throws {
        var opponentToken = Token(playerID: 1)
        opponentToken.isFinished = true

        viewModel.state.tokens[1] = [opponentToken, Token(playerID: 1), Token(playerID: 1), Token(playerID: 1)]

        let hasOpponent = viewModel.hasOpponentTokenAtCell(GameEngine.HOUSE, playerID: 0)
        XCTAssertFalse(hasOpponent, "Tokens in house cannot be captured")
    }


    // MARK: - Path Info Tests

    func testGetPathInfo_ValidPath() throws {
        var token = Token(playerID: 0)
        token.isOnBoard = true
        token.pathIndex = 5

        viewModel.state.tokens[0] = [token, Token(playerID: 0), Token(playerID: 0), Token(playerID: 0)]

        let pathInfo = viewModel.getPathInfo(playerID: 0, tokenIndex: 0, move: 3)
        XCTAssertGreaterThan(pathInfo.pathCells.count, 0, "Should have path cells")
        XCTAssertNotNil(pathInfo.finalCell, "Should have final cell")
    }
}
