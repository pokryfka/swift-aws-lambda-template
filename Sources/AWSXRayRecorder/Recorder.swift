import NIO
import NIOConcurrencyHelpers

/// # References
/// - [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private let lock = Lock()

    private var _traceId = TraceID()
    private var _segments = [Segment]()

    public init() {}

    private func beginSegment(name: String, parentId: String?, subsegment: Bool) -> Segment {
        lock.withLock {
            let newSegment = Segment(
                name: name, traceId: _traceId, parentId: parentId, subsegment: subsegment)
            _segments.append(newSegment)
            return newSegment
        }
    }

    public func beginSegment(name: String, parentId: String? = nil) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: false)
    }

    public func beginSubsegment(name: String, parentId: String) -> Segment {
        beginSegment(name: name, parentId: parentId, subsegment: true)
    }

    public func beginSegment(name: String, traceHeader: TraceHeader?) -> Segment {
        if let traceHeader = traceHeader {
            lock.withLockVoid { _traceId = traceHeader.root }
        }
        return beginSegment(
            name: name, parentId: traceHeader?.parentId, subsegment: traceHeader?.parentId != nil)
    }

    public var segments: [Segment] {
        lock.withLock { self._segments }
    }
}
