import NIO
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment

final class AWSXRayRecorderTests: XCTestCase {
    func testRecordingOneSegment() {
        let recorder = XRayRecorder()

        let segmentName = UUID().uuidString
        let segmentParentId = Segment.generateId()

        let segment = recorder.beginSegment(name: segmentName, parentId: segmentParentId)
        XCTAssertNotNil(recorder.segments.first)
        XCTAssertEqual(recorder.segments.first?.name, segmentName)
        XCTAssertEqual(recorder.segments.first?.parentId, segmentParentId)
        XCTAssertEqual(recorder.segments.first?.inProgress, true)
        segment.end()
        XCTAssertEqual(recorder.segments.first?.inProgress, false)
        XCTAssertNotNil(recorder.segments.first?.endTime)
        XCTAssertLessThan(recorder.segments.first!.endTime!, Date().timeIntervalSince1970)
    }

    func testRecordingOneSegmentClosure() {
        let recorder = XRayRecorder()

        let segmentName = UUID().uuidString
        let segmentParentId = Segment.generateId()

        recorder.segment(name: segmentName, parentId: segmentParentId) { segment in
            XCTAssertNotNil(recorder.segments.first)
            XCTAssertEqual(recorder.segments.first?.name, segmentName)
            XCTAssertEqual(recorder.segments.first?.parentId, segmentParentId)
            XCTAssertEqual(recorder.segments.first?.inProgress, true)
        }
        XCTAssertEqual(recorder.segments.first?.inProgress, false)
        XCTAssertNotNil(recorder.segments.first?.endTime)
        XCTAssertLessThan(recorder.segments.first!.endTime!, Date().timeIntervalSince1970)
    }

    // TODO: define more tests
}
