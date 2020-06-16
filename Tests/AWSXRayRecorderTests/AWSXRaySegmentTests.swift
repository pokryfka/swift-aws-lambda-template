import Foundation
import XCTest

@testable import AWSXRayRecorder

final class AWSXRaySegmentTests: XCTestCase {
    func testSegmentRandomId() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<String>()
        for _ in 0..<numTests {
            let segmendId = Segment.randomId()
            XCTAssertEqual(segmendId.count, 16)
            XCTAssertNil(segmendId.rangeOfCharacter(from: invalidCharacters))
            values.insert(segmendId)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTraceingHeaderValueRootNoParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        let value = try? TracingHeaderValue(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertNil(value?.parentId)
        XCTAssertTrue(value!.sampled)
    }

    func testTraceingHeaderValueRootWithParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1"
        let value = try? TracingHeaderValue(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertEqual(value?.parentId, "53995c3f42cd8ad8")
        XCTAssertTrue(value!.sampled)
    }

    static var allTests = [
        ("testSegmentRandomId", testSegmentRandomId),
        ("testTraceingHeaderValueRootNoParent", testTraceingHeaderValueRootNoParent),
        ("testTraceingHeaderValueRootWithParent", testTraceingHeaderValueRootWithParent),
    ]
}
