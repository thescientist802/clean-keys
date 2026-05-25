import XCTest
@testable import CleanKeys

final class StateMachineTests: XCTestCase {

    var stateMachine: StateMachine!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine()
    }

    override func tearDown() {
        stateMachine = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(stateMachine.state, .normal)
    }

    func testNormalToActivatedTransition() {
        stateMachine.transition(to: .activated)
        XCTAssertEqual(stateMachine.state, .activated)
    }

    func testActivatedToCleaningTransition() {
        stateMachine.transition(to: .activated)
        stateMachine.transition(to: .cleaning)
        XCTAssertEqual(stateMachine.state, .cleaning)
    }

    func testNormalToCleaningDirectTransition() {
        stateMachine.transition(to: .cleaning)
        XCTAssertEqual(stateMachine.state, .cleaning)
    }

    func testCleaningToExitingTransition() {
        stateMachine.transition(to: .activated)
        stateMachine.transition(to: .cleaning)
        stateMachine.transition(to: .exiting)
        XCTAssertEqual(stateMachine.state, .exiting)
    }

    func testExitingToNormalTransition() {
        stateMachine.transition(to: .activated)
        stateMachine.transition(to: .cleaning)
        stateMachine.transition(to: .exiting)
        stateMachine.transition(to: .normal)
        XCTAssertEqual(stateMachine.state, .normal)
    }

    func testInvalidTransitionCleaningToNormal() {
        stateMachine.transition(to: .activated)
        stateMachine.transition(to: .cleaning)
        stateMachine.transition(to: .normal)
        XCTAssertEqual(stateMachine.state, .cleaning)
    }

    func testInvalidTransitionNormalToExiting() {
        stateMachine.transition(to: .exiting)
        XCTAssertEqual(stateMachine.state, .normal)
    }

    func testFullLifecycle() {
        XCTAssertEqual(stateMachine.state, .normal)
        stateMachine.transition(to: .activated)
        XCTAssertEqual(stateMachine.state, .activated)
        stateMachine.transition(to: .cleaning)
        XCTAssertEqual(stateMachine.state, .cleaning)
        stateMachine.transition(to: .exiting)
        XCTAssertEqual(stateMachine.state, .exiting)
        stateMachine.transition(to: .normal)
        XCTAssertEqual(stateMachine.state, .normal)
    }

    func testStateNotification() {
        let expectation = expectation(description: "State change notification")

        NotificationCenter.default.addObserver(
            forName: .stateMachineDidChange,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertEqual(notification.userInfo?["newState"] as? AppState, .activated)
            expectation.fulfill()
        }

        stateMachine.transition(to: .activated)
        waitForExpectations(timeout: 1)
    }
}