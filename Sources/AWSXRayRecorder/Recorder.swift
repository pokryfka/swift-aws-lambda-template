import NIO

/// - See: [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
public class XRayRecorder {
    private var currentSegment: Segment?

    public func beginSubSegment(name: String, traceId: String, parentId: String?) {
        // TODO: add metadata
        // TODO: check if traceId and parentId are the same as the current segment, otherwise - end the current?
        // TODO: protect with lock
        let newSegment = Segment(name: name, traceId: traceId, parentId: parentId)
        if var segment = currentSegment {
            segment.subsegments.append(newSegment)
            currentSegment = segment
        } else {
            currentSegment = newSegment
        }
    }

    public func endSubSegment() {
        // TODO: protect with lock
        currentSegment?.end()
    }

    func sendSegments(emmiter: Emmiter) -> EventLoopFuture<Void> {
        // TODO: protect with lock
        endSubSegment()
        // TODO: check if sampled
        let segment = currentSegment
        currentSegment = nil

        if let segment = segment {
            return emmiter.send(segments: [segment])
        } else {
            return emmiter.eventLoop.makePromise(of: Void.self).futureResult
        }
    }
}
