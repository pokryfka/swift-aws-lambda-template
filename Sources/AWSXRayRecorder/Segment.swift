import Foundation
import NIOConcurrencyHelpers

extension XRayRecorder {

    /// A segment records tracing information about a request that your application serves.
    /// At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
    ///
    /// # References
    /// - [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    public class Segment: Encodable {
        enum SegmentError: Error {
            case AlreadyEmitted
        }

        enum SegmentType: String, Encodable {
            case subsegment
        }

        internal let lock = Lock()

        // MARK: Required Segment Fields

        /// The logical name of the service that handled the request, up to **200 characters**.
        /// For example, your application's name or domain name.
        /// Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
        let name: String

        /// A 64-bit identifier for the segment, unique among segments in the same trace, in **16 hexadecimal digits**.
        let id: String

        /// A unique identifier that connects all segments and subsegments originating from a single client request.
        ///
        /// # Trace ID Format
        /// A trace_id consists of three numbers separated by hyphens.
        ///
        /// For example, 1-58406520-a006649127e371903a2de979. This includes:
        /// - The version number, that is, 1.
        /// - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**. For example, 10:00AM December 1st, 2016 PST in epoch time is 1480615200 seconds, or 58406520 in hexadecimal digits.
        ///  - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
        ///
        /// # Trace ID Security
        /// Trace IDs are visible in response headers. Generate trace IDs with a secure random algorithm to ensure that attackers cannot calculate future trace IDs and send requests with those IDs to your application.
        let traceId: TraceID

        /// **number** that is the time the segment was created, in floating point seconds in epoch time.
        /// For example, 1480615200.010 or 1.480615200010E9.
        /// Use as many decimal places as you need. Microsecond resolution is recommended when available.
        let startTime: Double

        /// **number** that is the time the segment was closed.
        /// For example, 1480615200.090 or 1.480615200090E9.
        /// Specify either an end_time or in_progress.
        private(set) var endTime: Double?

        /// **boolean**, set to true instead of specifying an end_time to record that a segment is started, but is not complete.
        /// Send an in-progress segment when your application receives a request that will take a long time to serve, to trace the request receipt.
        /// When the response is sent, send the complete segment to overwrite the in-progress segment.
        /// Only send one complete segment, and one or zero in-progress segments, per request.
        var inProgress: Bool { endTime == nil }

        // MARK: Optional Segment Fields

        // TODO: add optional attributes, implement custom encoder which will omit nil and not required attributes

        /// A subsegment ID you specify if the request originated from an instrumented application.
        /// The X-Ray SDK adds the parent subsegment ID to the tracing header for downstream HTTP calls.
        /// In the case of nested subsguments, a subsegment can have a segment or a subsegment as its parent.
        let parentId: String?

        // TODO: add annotations and metadata

        /// array of subsegment objects.
        private var subsegments: [Segment]?

        /// Required only if sending a subsegment separately.
        private(set) var type: SegmentType?

        init(name: String, traceId: TraceID, parentId: String?, subsegment: Bool) {
            self.name = name
            self.id = Self.generateId()
            self.traceId = traceId
            self.startTime = Date().timeIntervalSince1970
            self.parentId = parentId
            if parentId != nil && subsegment {
                self.type = .subsegment
            }
        }

        enum CodingKeys: String, CodingKey {
            case name, id
            case traceId = "trace_id"
            case startTime = "start_time"
            case endTime = "end_time"
            //            case inProgress = "in_progress"
            case type
            case parentId = "parent_id"
            case subsegments
        }
    }

}

extension XRayRecorder.Segment {
    public func beginSubSegment(name: String) -> XRayRecorder.Segment {
        lock.withLock {
            let newSegment = XRayRecorder.Segment(
                name: name, traceId: traceId, parentId: id, subsegment: true)
            if (subsegments?.count ?? 0) > 0 {
                subsegments?.append(newSegment)
            } else {
                subsegments = [newSegment]
            }
            return newSegment
        }
    }

    /// Updates `endTime` of the Segment, ends subsegments if not ended.
    public func end() {
        let now = Date().timeIntervalSince1970
        end(date: now)
    }

    func end(date: Double) {
        lock.withLockVoid {
            if endTime == nil {
                endTime = date
            }
            let date = endTime ?? date
            subsegments?.forEach { $0.end(date: date) }
        }
    }

    func addDuration(seconds: Double) {
        lock.withLockVoid {
            guard seconds >= 0 else { return }
            let date = endTime ?? startTime
            endTime = date + seconds
        }
    }
}

extension XRayRecorder.Segment {
    /// - returns: A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.
    static func generateId() -> String {
        String(format: "%llx", UInt64.random(in: UInt64.min...UInt64.max) | 1 << 63)
    }
}
