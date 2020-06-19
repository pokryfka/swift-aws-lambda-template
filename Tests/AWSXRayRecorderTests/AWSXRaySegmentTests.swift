import Foundation
import XCTest

@testable import AWSXRayRecorder

final class AWSXRaySegmentTests: XCTestCase {
    func testTraceRandomIdenifier() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<String>()
        for _ in 0..<numTests {
            let identifier = TraceId.randomIdenifier()
            XCTAssertEqual(identifier.count, 24)
            XCTAssertNil(identifier.rangeOfCharacter(from: invalidCharacters))
            values.insert(identifier)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTraceRandomId() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<TraceId>()
        for _ in 0..<numTests {
            let traceId = TraceId()
            XCTAssertEqual(traceId.date.count, 8)
            XCTAssertNil(traceId.date.rangeOfCharacter(from: invalidCharacters))
            XCTAssertEqual(traceId.identifier.count, 24)
            XCTAssertNil(traceId.identifier.rangeOfCharacter(from: invalidCharacters))
            XCTAssertNoThrow(try TraceId(string: String(describing: traceId)))
            values.insert(traceId)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTracingHeaderValueRootNoParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        let value = try? TracingHeaderValue(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root.description, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertNil(value?.parentId)
        XCTAssertTrue(value!.sampled)
    }

    func testTracingHeaderValueRootWithParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1"
        let value = try? TracingHeaderValue(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root.description, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertEqual(value?.parentId, "53995c3f42cd8ad8")
        XCTAssertTrue(value!.sampled)
    }
    func testTracingHeaderValueInvalid() {
        let string = "Root=-2799;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TracingHeaderValue(string: string)) { error in
            if case TraceIdError.invalidTraceId(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-2799")
            } else {
                XCTFail()
            }
        }
    }

    // MARK: Segment

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
}
