import XCTest
@testable import CleanKeys

final class FailSafeTests: XCTestCase {

    var stateMachine: StateMachine!
    var failSafeManager: FailSafeManager!

    override func setUp() {
        super.setUp()
        clearPersistedState()
        stateMachine = StateMachine()
        failSafeManager = FailSafeManager(stateMachine: stateMachine)
    }

    private func clearPersistedState() {
        let fm = FileManager.default
        guard let basePath = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let path = basePath
            .appendingPathComponent("com.scientist.CleanKeys")
            .appendingPathComponent("state.json")
        try? fm.removeItem(at: path)
    }

    override func tearDown() {
        failSafeManager.cancel()
        failSafeManager = nil
        stateMachine = nil
        super.tearDown()
    }

    func testCountdownStartsCorrectly() {
        failSafeManager.startCountdown(timeoutSeconds: 600)
        XCTAssertEqual(failSafeManager.countdownText, "10:00")
    }

    func testCountdownDecrements() {
        stateMachine.transition(to: .cleaning)

        let expectation = expectation(description: "Countdown completes")

        let observer = NotificationCenter.default.addObserver(
            forName: .stateMachineDidChange,
            object: stateMachine,
            queue: .main
        ) { notification in
            if let newState = notification.userInfo?["newState"] as? AppState, newState == .exiting {
                expectation.fulfill()
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        failSafeManager.cancel()
        failSafeManager.startCountdown(timeoutSeconds: 3)
        waitForExpectations(timeout: 10)
    }

    func testCancelStopsCountdown() {
        failSafeManager.startCountdown(timeoutSeconds: 600)
        failSafeManager.cancel()
        XCTAssertEqual(failSafeManager.countdownText, "")
    }

    func testExtendIncreasesTimeout() {
        failSafeManager.startCountdown(timeoutSeconds: 100)
        failSafeManager.extend(by: 300)
        XCTAssertEqual(failSafeManager.countdownText, "06:40")
    }

    func testZeroTimeoutTransitionsToExiting() {
        stateMachine.transition(to: .cleaning)
        failSafeManager.cancel()
        failSafeManager.startCountdown(timeoutSeconds: 0)
        XCTAssertEqual(stateMachine.state, .exiting, "Expected exiting after zero timeout, got \(stateMachine.state)")
    }

    func testExtendWhenInactiveIsNoOp() {
        failSafeManager.extend(by: 300)
        XCTAssertEqual(failSafeManager.countdownText, "")
    }
}