import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias TraceID = XRayRecorder.TraceID
private typealias TraceHeader = XRayRecorder.TraceHeader
private typealias TraceError = XRayRecorder.TraceError

final class AWSXRayTraceTests: XCTestCase {
    func testTraceRandomIdenifier() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<String>()
        for _ in 0..<numTests {
            let identifier = TraceID.generateIdentifier()
            XCTAssertEqual(identifier.count, 24)
            XCTAssertNil(identifier.rangeOfCharacter(from: invalidCharacters))
            values.insert(identifier)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTraceRandomId() {
        let numTests = 1000
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        var values = Set<TraceID>()
        for _ in 0..<numTests {
            let traceId = TraceID()
            XCTAssertEqual(traceId.date.count, 8)
            XCTAssertNil(traceId.date.rangeOfCharacter(from: invalidCharacters))
            XCTAssertEqual(traceId.identifier.count, 24)
            XCTAssertNil(traceId.identifier.rangeOfCharacter(from: invalidCharacters))
            XCTAssertNoThrow(try TraceID(string: String(describing: traceId)))
            values.insert(traceId)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTracingHeaderValueRootNoParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        let value = try? TraceHeader(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root.description, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertNil(value?.parentId)
        XCTAssertTrue(value!.sampled)
    }

    func testTracingHeaderValueRootWithParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1"
        let value = try? TraceHeader(string: string)
        XCTAssertNotNil(value)
        XCTAssertEqual(value?.root.description, "1-5759e988-bd862e3fe1be46a994272793")
        XCTAssertEqual(value?.parentId, "53995c3f42cd8ad8")
        XCTAssertTrue(value!.sampled)
    }
    func testTracingHeaderValueInvalid() {
        let string = "Root=-2799;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TraceHeader(string: string)) { error in
            if case TraceError.invalidTraceID(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-2799")
            } else {
                XCTFail()
            }
        }
    }
}
