import AnyCodable
import Foundation
import NIOConcurrencyHelpers

extension XRayRecorder {
    enum SegmentError: Error {
        case invalidID(String)
        //            case AlreadyEmitted

    }

    /// A segment records tracing information about a request that your application serves.
    /// At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
    ///
    /// # References
    /// - [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    public class Segment: Encodable {
        enum AnnotationValue {
            case string(String)
            case int(Int)
            case float(Float)
            case bool(Bool)
        }

        enum SegmentType: String, Encodable {
            case subsegment
        }

        /// Segments and subsegments can include an annotations object containing one or more fields that
        /// X-Ray indexes for use with filter expressions.
        /// Fields can have string, number, or Boolean values (no objects or arrays).
        /// X-Ray indexes up to 50 annotations per trace.
        ///
        /// Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.
        typealias Annotations = [String: AnnotationValue]

        /// Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays.
        /// X-Ray does not index metadata, and values can be any size, as long as the segment document doesn't exceed the maximum size (64 kB).
        /// You can view metadata in the full segment document returned by the BatchGetTraces API.
        /// Field keys (debug in the following example) starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.
        public typealias Metadata = [String: AnyEncodable]

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

        /// A subsegment ID you specify if the request originated from an instrumented application.
        /// The X-Ray SDK adds the parent subsegment ID to the tracing header for downstream HTTP calls.
        /// In the case of nested subsguments, a subsegment can have a segment or a subsegment as its parent.
        let parentId: String?

        /// annotations object with key-value pairs that you want X-Ray to index for search.
        private var annotations: Annotations?

        /// metadata object with any additional data that you want to store in the segment.
        private var metadata: Metadata?

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
            // case inProgress = "in_progress"
            case type
            case parentId = "parent_id"
            case annotations, metadata
            case subsegments
        }
    }

}

// MARK: End time

extension XRayRecorder.Segment {
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

// MARK: Annotations and Metadata

extension XRayRecorder.Segment {
    func addAnnotations(_ newElements: Annotations) {
        lock.withLock {
            if (annotations?.count ?? 0) > 0 {
                for (k, v) in newElements {
                    annotations?.updateValue(v, forKey: k)
                }
            } else {
                annotations = newElements
            }
        }
    }

    public func addAnnotation(_ key: String, value: Bool) {
        addAnnotations([key: .bool(value)])
    }

    public func addAnnotation(_ key: String, value: Int) {
        addAnnotations([key: .int(value)])
    }

    public func addAnnotation(_ key: String, value: Float) {
        addAnnotations([key: .float(value)])
    }

    public func addAnnotation(_ key: String, value: String) {
        addAnnotations([key: .string(value)])
    }

    public func addMetadata(_ newElements: Metadata) {
        lock.withLock {
            if (metadata?.count ?? 0) > 0 {
                for (k, v) in newElements {
                    metadata?.updateValue(v, forKey: k)
                }
            } else {
                metadata = newElements
            }
        }
    }
}

extension XRayRecorder.Segment.AnnotationValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: Subsegments

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
}

// MARK: Id

extension XRayRecorder.Segment {
    /// - returns: A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.
    static func generateId() -> String {
        String(format: "%llx", UInt64.random(in: UInt64.min...UInt64.max) | 1 << 63)
    }

    static func validateId(_ string: String) throws -> String {
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        guard
            16 == string.count,
            nil == string.rangeOfCharacter(from: invalidCharacters)
        else {
            throw XRayRecorder.SegmentError.invalidID(string)
        }
        return string
    }
}
