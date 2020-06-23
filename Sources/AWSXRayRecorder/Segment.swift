import AnyCodable
import Foundation
import NIOConcurrencyHelpers

extension XRayRecorder {
    enum SegmentError: Error {
        case invalidID(String)
        //case alreadyEmitted
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

        /// An object with information about your application.
        public struct Service: Encodable {
            /// A string that identifies the version of your application that served the request.
            let version: String
        }

        /// The type of AWS resource running your application.
        ///
        /// When multiple values are applicable to your application, use the one that is most specific.
        /// For example, a Multicontainer Docker Elastic Beanstalk environment runs your application on an Amazon ECS container,
        /// which in turn runs on an Amazon EC2 instance.
        /// In this case you would set the origin to `AWS::ElasticBeanstalk::Environment` as the environment is the parent of the other two resources.
        public enum Origin: String, Encodable {
            /// An Amazon EC2 instance.
            case ec2Instance = "AWS::EC2::Instance"
            /// An Amazon ECS container.
            case ecsContainer = "AWS::ECS::Container"
            /// An Elastic Beanstalk environment.
            case elasticBeanstalk = "AWS::ElasticBeanstalk::Environment"
        }

        /// Use an HTTP block to record details about an HTTP request that your application served (in a segment) or that your application made to a downstream HTTP API (in a subsegment). Most of the fields in this object map to information found in an HTTP request and response.
        ///
        /// When you instrument a call to a downstream web api, record a subsegment with information about the HTTP request and response.
        /// X-Ray uses the subsegment to generate an inferred segment for the remote API.
        ///
        /// # References
        /// - [AWS X-Ray segment documents - HTTP request data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-http)
        public struct HTTP: Encodable {
            /// Information about a request.
            struct Request: Encodable {
                /// The request method. For example, GET.
                var method: String?
                /// The full URL of the request, compiled from the protocol, hostname, and path of the request.
                var url: String?
                /// The user agent string from the requester's client.
                var userAgent: String?
                /// The IP address of the requester.
                /// Can be retrieved from the IP packet's Source Address or, for forwarded requests, from an `X-Forwarded-For` header.
                var clientIP: String?
                /// (segments only) **boolean** indicating that the `client_ip` was read from an `X-Forwarded-For` header and
                /// is not reliable as it could have been forged.
                var forwardedFor: Bool?
                /// (subsegments only) **boolean** indicating that the downstream call is to another traced service.
                /// If this field is set to `true`, X-Ray considers the trace to be broken until the downstream service uploads a segment with a `parent_id` that
                /// matches the `id` of the subsegment that contains this block.
                var traced: Bool?
            }

            /// Information about a response.
            struct Response: Encodable {
                /// number indicating the HTTP status of the response.
                var status: UInt?
                /// number indicating the length of the response body in bytes.
                var contentLength: UInt64?
            }

            var request: Request?
            var response: Response?
        }

        /// For segments, the aws object contains information about the resource on which your application is running.
        /// Multiple fields can apply to a single resource. For example, an application running in a multicontainer Docker environment on
        /// Elastic Beanstalk could have information about the Amazon EC2 instance, the Amazon ECS container running on the instance,
        /// and the Elastic Beanstalk environment itself.
        ///
        /// # References
        /// - [AWS X-Ray segment documents - AWS resource data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-aws)
        public struct AWS: Encodable {
            /// If your application sends segments to a different AWS account, record the ID of the account running your application.
            var accountId: String?

            // MARK: Segments

            /// Information about an Amazon ECS container.
            struct ECS: Encodable {
                /// The container ID of the container running your application.
                let container: String?
            }

            /// Information about an EC2 instance.
            struct EC2: Encodable {
                /// The instance ID of the EC2 instance.
                let instanceId: String?
                /// The Availability Zone in which the instance is running.
                let availabilityZone: String?
            }

            /// Information about an Elastic Beanstalk environment.
            /// You can find this information in a file named `/var/elasticbeanstalk/xray/environment.conf`
            /// on the latest Elastic Beanstalk platforms.
            struct ElasticBeanstalk: Encodable {
                /// The name of the environment.
                var environmentName: String?
                /// The name of the application version that is currently deployed to the instance that served the request.
                var versionLabel: String?
                /// **number** indicating the ID of the last successful deployment to the instance that served the request.
                var deploymentId: Int?
            }

            /// Information about an Amazon ECS container.
            var ecs: ECS?
            /// Information about an EC2 instance.
            var ec2: EC2?
            /// Information about an Elastic Beanstalk environment.
            var elasticBeanstalk: ElasticBeanstalk?

            // MARK: Subsegments

            /// The name of the API action invoked against an AWS service or resource.
            var operation: String?
            /// If the resource is in a region different from your application, record the region. For example, `us-west-2`.
            var region: String?
            /// Unique identifier for the request.
            var requestId: String?
            /// For operations on an Amazon SQS queue, the queue's URL.
            var queueURL: String?
            /// For operations on a DynamoDB table, the name of the table.
            var tableName: String?
        }

        struct Exception: Encodable {
            /// A 64-bit identifier for the exception, unique among segments in the same trace, in **16 hexadecimal digits**.
            let id: String
            /// The exception message.
            var message: String?

            // TODO: other optional attributes
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
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
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
        ///
        /// # Subsegment
        /// Required only if sending a subsegment separately.
        /// In the case of nested subsegments, a subsegment can have a segment or a subsegment as its parent.
        let parentId: String?

        /// # Subsegment
        /// Required only if sending a subsegment separately.
        private(set) var type: SegmentType?

        /// An object with information about your application.
        private var _service: Service?

        /// A string that identifies the user who sent the request.
        private var _user: String?

        /// The type of AWS resource running your application.
        private var _origin: Origin?

        /// http objects with information about the original HTTP request.
        private var _http: HTTP?

        /// aws object with information about the AWS resource on which your application served the request
        private var _aws: AWS?

        /// **boolean** indicating that a client error occurred (response status code was 4XX Client Error).
        private var error: Bool?
        /// **boolean** indicating that a request was throttled (response status code was 429 Too Many Requests).
        private var throttle: Bool?
        /// **boolean** indicating that a server error occurred (response status code was 5XX Server Error).
        private var fault: Bool?
        private var cause: Exception?

        /// annotations object with key-value pairs that you want X-Ray to index for search.
        private var annotations: Annotations?

        /// metadata object with any additional data that you want to store in the segment.
        private var metadata: Metadata?

        /// array of subsegment objects.
        private var subsegments: [Segment]?

        init(
            name: String, traceId: TraceID, parentId: String?, subsegment: Bool,
            service: Service? = nil, user: String? = nil,
            origin: Origin? = nil, http: HTTP? = nil, aws: AWS? = nil,
            annotations: Annotations? = nil, metadata: Metadata? = nil
        ) {
            self.name = name
            self.id = Self.generateId()
            self.traceId = traceId
            self.startTime = Date().timeIntervalSince1970
            self.parentId = parentId
            self.type = subsegment && parentId != nil ? .subsegment : nil
            self._service = service
            self._user = user
            self._http = http
            self._aws = aws
            self.annotations = annotations
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case name, id
            case traceId = "trace_id"
            case startTime = "start_time"
            case endTime = "end_time"
            // case inProgress = "in_progress"
            case type
            case parentId = "parent_id"
            case _service = "service"
            case _user = "user"
            case _origin = "origin"
            case _http = "http"
            case _aws = "aws"
            case error, throttle, fault, cause
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

    //    func addDuration(seconds: Double) {
    //        lock.withLockVoid {
    //            guard seconds >= 0 else { return }
    //            let date = endTime ?? startTime
    //            endTime = date + seconds
    //        }
    //    }
}

// MARK: Errors and exceptions

extension XRayRecorder.Segment {
    public func setError(_ error: Error) {
        let exception = Exception(
            id: XRayRecorder.Segment.generateId(),
            message: "\(error)")
        lock.withLockVoid {
            self.error = true
            cause = exception
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
    public func beginSubsegment(name: String) -> XRayRecorder.Segment {
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
}

// MARK: Validation

extension XRayRecorder.Segment {
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

    // TODO: validate name
}
