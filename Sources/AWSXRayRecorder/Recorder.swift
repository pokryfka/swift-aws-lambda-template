import NIO

/// - See: [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private var segments = [Segment]()

    private var currentSegment: Segment? { segments.last }

    public func beginSubSegment(name: String, traceId: String, parentId: String?) -> String {
        // TODO: add metadata
        let newSegment = Segment(name: name, traceId: traceId, parentId: parentId)
        // TODO: protect with lock
        // TODO: compare the logic here with different clients
        if let segment = currentSegment,
            newSegment.traceId == segment.traceId && newSegment.parentId == segment.id
        {
            // TODO: don to allow to add subsegment if parent ended
            segment.subsegments.append(newSegment)
        } else {
            currentSegment?.end()
            segments.append(newSegment)
        }

        return newSegment.id
    }

    public func endSubSegment() {
        // TODO: protect with lock
        currentSegment?.end()
    }

    func sendSegments(emmiter: Emmiter) -> EventLoopFuture<Void> {
        // TODO: protect with lock
        endSubSegment()
        // TODO: check if sampled
        let sampledSegments = segments
        segments.removeAll()

        if sampledSegments.isEmpty == false {
            return emmiter.send(segments: sampledSegments)
        } else {
            return emmiter.eventLoop.makePromise(of: Void.self).futureResult
        }
    }
}
