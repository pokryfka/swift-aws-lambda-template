import NIO
import XCTest

@testable import AWSXRayRecorder

final class AWSXRayRecorderTests: XCTestCase {
    func testRecordingOneSegmentNoEnding() {
        let emmiter = MockEmmiter()
        let recorder = XRayRecorder()

        let testName = UUID().uuidString  // this is technically invalid trace id, not sure about dashes
        let testTraceId = UUID().uuidString  // this is technically invalid trace id
        let testparentId = UUID().uuidString
        _ = recorder.beginSubSegment(name: testName, traceId: testTraceId, parentId: testparentId)

        _ = recorder.sendSegments(emmiter: emmiter)

        XCTAssertEqual(emmiter.documents.count, 1)
        XCTAssertEqual(emmiter.documents.first?.count, 1)

        let segment = emmiter.documents.first?.first
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, testName)
        XCTAssertEqual(segment?.traceId, testTraceId)
        XCTAssertEqual(segment?.parentId, testparentId)
        XCTAssertEqual(segment?.subsegments.count, 0)
    }

    func testRecordingOneSegmentWithEnding() {
        let emmiter = MockEmmiter()
        let recorder = XRayRecorder()

        let testName = UUID().uuidString  // this is technically invalid trace id, not sure about dashes
        let testTraceId = UUID().uuidString  // this is technically invalid trace id
        let testparentId = UUID().uuidString
        _ = recorder.beginSubSegment(name: testName, traceId: testTraceId, parentId: testparentId)
        recorder.endSubSegment()
        _ = recorder.sendSegments(emmiter: emmiter)

        XCTAssertEqual(emmiter.documents.count, 1)
        XCTAssertEqual(emmiter.documents.first?.count, 1)

        let segment = emmiter.documents.first?.first
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, testName)
        XCTAssertEqual(segment?.traceId, testTraceId)
        XCTAssertEqual(segment?.parentId, testparentId)
        XCTAssertEqual(segment?.subsegments.count, 0)
    }

    func testRecordingTwoSegmentNoEnding() {
        let emmiter = MockEmmiter()
        let recorder = XRayRecorder()

        let testName = UUID().uuidString
        let testTraceId = TraceId()
        let segmentId = recorder.beginSubSegment(
            name: testName,
            traceId: String(describing: testTraceId),
            parentId: nil)

        let testName2 = UUID().uuidString
        _ = recorder.beginSubSegment(
            name: testName2,
            traceId: String(describing: testTraceId),
            parentId: segmentId)

        _ = recorder.sendSegments(emmiter: emmiter)

        XCTAssertEqual(emmiter.documents.count, 1)

        let segments = emmiter.documents.first
        XCTAssertEqual(segments?.count, 1)

        let segment = segments?.first
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, testName)
        XCTAssertEqual(segment?.traceId, testTraceId.description)
        XCTAssertEqual(segment?.parentId, nil)
        XCTAssertEqual(segment?.subsegments.count, 1)

        let subsegment = segment?.subsegments.first
        XCTAssertNotNil(subsegment)
        XCTAssertEqual(subsegment?.name, testName2)
        XCTAssertEqual(subsegment?.traceId, testTraceId.description)
        XCTAssertEqual(subsegment?.parentId, segmentId)
        XCTAssertEqual(subsegment?.subsegments.count, 0)
    }
}
