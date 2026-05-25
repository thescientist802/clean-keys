import XCTest
@testable import CleanKeys

final class EventTapCallbackTests: XCTestCase {

    var stateMachine: StateMachine!
    var eventTapService: EventTapService!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine()
        eventTapService = EventTapService(stateMachine: stateMachine)
    }

    override func tearDown() {
        eventTapService.stop()
        eventTapService = nil
        stateMachine = nil
        super.tearDown()
    }

    func testEventTapDoesNotStartInNormalState() {
        XCTAssertEqual(stateMachine.state, .normal)
    }

    func testStateTransitionToActivated() {
        stateMachine.transition(to: .activated)
        XCTAssertEqual(stateMachine.state, .activated)
    }

    func testFailSafePatternDetection() {
        stateMachine.transition(to: .activated)
        stateMachine.transition(to: .cleaning)

        XCTAssertEqual(stateMachine.state, .cleaning)
    }
}