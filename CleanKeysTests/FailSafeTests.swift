import XCTest
@testable import CleanKeys

final class FailSafeTests: XCTestCase {

    var stateMachine: StateMachine!
    var failSafeManager: FailSafeManager!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine()
        failSafeManager = FailSafeManager(stateMachine: stateMachine)
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
        failSafeManager.startCountdown(timeoutSeconds: 3)

        let expectation = expectation(description: "Countdown completes")

        let _ = NotificationCenter.default.addObserver(
            forName: .stateMachineDidChange,
            object: nil,
            queue: .main
        ) { notification in
            if let newState = notification.userInfo?["newState"] as? AppState, newState == .exiting {
                expectation.fulfill()
            }
        }

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
}