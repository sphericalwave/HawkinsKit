import XCTest
@testable import HawkinsKit

final class HawkinsCheckInTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suite = "HawkinsCheckInTests"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testLastFallsBackToDefaultsBeforeAnyAnswer() {
        let memory = HawkinsCheckInMemory(keyPrefix: "test")
        XCTAssertEqual(memory.last(in: defaults), .init(score: 540, intensity: 5))
    }

    func testRememberRoundTrips() {
        let memory = HawkinsCheckInMemory(keyPrefix: "test")
        memory.remember(.init(score: 500, intensity: 8), in: defaults)
        XCTAssertEqual(memory.last(in: defaults), .init(score: 500, intensity: 8))
        XCTAssertEqual(defaults.integer(forKey: "testLastScore"), 500)
    }

    func testRememberWithoutIntensityKeepsThePreviousOne() {
        let memory = HawkinsCheckInMemory(keyPrefix: "test")
        memory.remember(.init(score: 500, intensity: 8), in: defaults)
        memory.remember(.init(score: 600, intensity: nil), in: defaults)
        XCTAssertEqual(memory.last(in: defaults), .init(score: 600, intensity: 8))
    }

    func testPrefixesKeepAppsApart() {
        HawkinsCheckInMemory(keyPrefix: "a").remember(.init(score: 200, intensity: 1), in: defaults)
        XCTAssertEqual(HawkinsCheckInMemory(keyPrefix: "b").last(in: defaults).score, 540)
    }

    func testInitialPrefersTheExistingAnswer() {
        let last = HawkinsCheckIn.Answer(score: 540, intensity: 5)
        XCTAssertEqual(HawkinsCheckInMemory.initial(existing: 350, intensity: 9, last: last),
                       .init(score: 350, intensity: 9))
        XCTAssertEqual(HawkinsCheckInMemory.initial(existing: nil, intensity: nil, last: last), last)
    }

    func testInitialClampsIntensity() {
        let last = HawkinsCheckIn.Answer(score: 540, intensity: 5)
        XCTAssertEqual(HawkinsCheckInMemory.initial(existing: nil, intensity: 14, last: last).intensity, 10)
        XCTAssertEqual(HawkinsCheckInMemory.initial(existing: nil, intensity: -2, last: last).intensity, 0)
    }
}
