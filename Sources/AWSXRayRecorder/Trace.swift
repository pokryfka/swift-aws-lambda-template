import Foundation

extension XRayRecorder {
    enum TraceError: Error {
        case invalidTraceID(String)
        case invalidTraceHeader(String)
    }
}

extension XRayRecorder {
    /// # Trace ID Format
    /// A `trace_id` consists of three numbers separated by hyphens.
    /// For example, `1-58406520-a006649127e371903a2de979`. This includes:
    /// - The version number, that is, 1.
    /// - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**. For example, 10:00AM December 1st, 2016 PST in epoch time is `1480615200 seconds`, or `58406520` in hexadecimal digits.
    /// - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
    ///
    /// # References
    /// - [Sending trace data to AWS X-Ray - Generating trace IDs](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)
    struct TraceID: CustomStringConvertible {
        /// The version number, that is, 1.
        let version: UInt = 1
        /// The time of the original request, in Unix epoch time, in **8 hexadecimal digits**.
        /// For example, 10:00AM December 1st, 2016 PST in epoch time is 1480615200 seconds, or 58406520 in hexadecimal digits.
        let date: String
        /// A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
        let identifier: String

        var description: String {
            "\(version)-\(date)-\(identifier)"
        }
    }

}

extension XRayRecorder.TraceID: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(version)
        hasher.combine(date)
        hasher.combine(identifier)
    }
}

extension XRayRecorder.TraceID: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self))
    }
}

extension XRayRecorder.TraceID {
    /// - returns: A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.
    static func generateIdentifier() -> String {
        String(
            format: "%llx%llx", (UInt64.random(in: UInt64.min...UInt64.max) | 1 << 63),
            (UInt32.random(in: UInt32.min...UInt32.max) | 1 << 31))
    }

    /// Creates new Trace ID.
    init() {
        let now = Date().timeIntervalSince1970
        date = String(format: "%08x", Int(now))
        identifier = Self.generateIdentifier()
    }

    init(date: Double) {
        self.date = String(format: "%08x", Int(date))
        identifier = Self.generateIdentifier()
    }

    /// Parses and validates string with Trace ID.
    init(string: String) throws {
        let values = string.split(separator: "-")
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        guard
            3 == values.count,
            "1" == values[0],
            8 == values[1].count,
            24 == values[2].count,
            nil == values[1].rangeOfCharacter(from: invalidCharacters),
            nil == values[2].rangeOfCharacter(from: invalidCharacters)
        else {
            throw XRayRecorder.TraceError.invalidTraceID(string)
        }

        date = String(values[1])
        identifier = String(values[2])
    }
}

extension XRayRecorder {

    /// All requests are traced, up to a configurable minimum.
    /// After reaching that minimum, a percentage of requests are traced to avoid unnecessary cost.
    /// The sampling decision and trace ID are added to HTTP requests in **tracing headers** named `X-Amzn-Trace-Id`.
    /// The first X-Ray-integrated service that the request hits adds a tracing header, which is read by the X-Ray SDK and included in the response.
    ///
    /// # Example Tracing header with root trace ID and sampling decision:
    /// ```
    /// X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1
    /// ```
    ///
    /// # Tracing Header Security
    /// A tracing header can originate from the X-Ray SDK, an AWS service, or the client request.
    /// Your application can remove `X-Amzn-Trace-Id` from incoming requests to avoid issues caused by users adding trace IDs
    /// or sampling decisions to their requests.
    ///
    /// The tracing header can also contain a parent segment ID if the request originated from an instrumented application.
    /// For example, if your application calls a downstream HTTP web API with an instrumented HTTP client,
    /// the X-Ray SDK adds the segment ID for the original request to the tracing header of the downstream request.
    /// An instrumented application that serves the downstream request can record the parent segment ID to connect the two requests.
    ///
    /// # Example Tracing header with root trace ID, parent segment ID and sampling decision
    /// ```
    /// X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1
    /// ```
    ///
    ///  # References
    /// - [AWS X-Ray concepts - Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
    public struct TraceHeader {
        /// root trace ID
        let root: TraceID
        /// parent segment ID
        let parentId: String?
        /// sampling decision
        let sampled: Bool
    }
}

extension XRayRecorder.TraceHeader {
    /// Generate value with new Trace ID.
    init(parentId: String? = nil, sampled: Bool = true) {
        root = XRayRecorder.TraceID()
        self.parentId = parentId
        self.sampled = sampled
    }

    /// Parses and validates string with Tracing Header.
    public init(string: String) throws {
        // TODO: cleanup, add test case for string with ";" but without "="
        let values = string.split(separator: ";").map { $0.split(separator: "=") }
        let numValues = values.count
        guard
            numValues >= 2, numValues <= 3,
            values[0][0] == "Root",
            values[numValues - 1][0] == "Sampled"
        else {
            throw XRayRecorder.TraceError.invalidTraceHeader(string)
        }
        let sampledValue = values[numValues - 1][1]
        guard
            sampledValue == "1" || sampledValue == "0"
        else {
            throw XRayRecorder.TraceError.invalidTraceHeader(string)
        }
        self.root = try XRayRecorder.TraceID(string: String(values[0][1]))
        if values[1][0] == "Parent" {
            self.parentId = String(values[1][1])
        } else {
            self.parentId = nil
        }
        self.sampled = sampledValue == "1"
    }
}
