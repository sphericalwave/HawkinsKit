import XCTest
@testable import HawkinsKit

final class HawkinsLevelTests: XCTestCase {

    func testScaleHas17Levels() {
        XCTAssertEqual(Hawkins.scale.count, 17)
    }

    func testScaleIsAscendingWithNoGapsOrOverlaps() {
        let levels = Hawkins.scale
        for i in 0..<(levels.count - 1) {
            XCTAssertEqual(levels[i].scoreRange.upperBound + 1, levels[i + 1].scoreRange.lowerBound,
                            "\(levels[i].name) -> \(levels[i + 1].name) should be contiguous")
        }
        XCTAssertEqual(levels.first?.scoreRange.lowerBound, 0)
        XCTAssertEqual(levels.last?.scoreRange.upperBound, 1000)
    }

    func testLevelForBoundaryScores() {
        XCTAssertEqual(Hawkins.level(for: 0).id, "shame")
        XCTAssertEqual(Hawkins.level(for: 29).id, "shame")
        XCTAssertEqual(Hawkins.level(for: 30).id, "guilt")
        XCTAssertEqual(Hawkins.level(for: 200).id, "courage")
        XCTAssertEqual(Hawkins.level(for: 249).id, "courage")
        XCTAssertEqual(Hawkins.level(for: 250).id, "neutrality")
        XCTAssertEqual(Hawkins.level(for: 700).id, "enlightenment")
        XCTAssertEqual(Hawkins.level(for: 1000).id, "enlightenment")
    }

    func testLevelForClampsOutOfRangeScores() {
        XCTAssertEqual(Hawkins.level(for: -50).id, "shame")
        XCTAssertEqual(Hawkins.level(for: 5000).id, "enlightenment")
    }

    func testColorForIsDefinedAcrossFullRange() {
        for score in stride(from: 0, through: 1000, by: 25) {
            _ = Hawkins.color(for: score)
        }
    }

    func testColorForClampsOutOfRangeScores() {
        XCTAssertEqual(Hawkins.color(for: -100), Hawkins.color(for: 0))
        XCTAssertEqual(Hawkins.color(for: 5000), Hawkins.color(for: 1000))
    }
}
