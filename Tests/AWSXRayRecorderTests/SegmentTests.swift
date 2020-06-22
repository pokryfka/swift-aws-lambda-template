import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias TraceID = XRayRecorder.TraceID
private typealias TraceHeader = XRayRecorder.TraceHeader
private typealias TraceError = XRayRecorder.TraceError

final class AWSXRaySegmentTests: XCTestCase {
    func testSegmentRandomId() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<String>()
        for _ in 0..<numTests {
            let segmendId = XRayRecorder.Segment.generateId()
            XCTAssertEqual(segmendId.count, 16)
            XCTAssertNil(segmendId.rangeOfCharacter(from: invalidCharacters))
            values.insert(segmendId)
        }
        XCTAssertEqual(values.count, numTests)
    }
}
