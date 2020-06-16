import Foundation

enum XRayRecorderTraceIdError: Error {
    //    case invalidTraceId(String)
    case invalidTracingHeaderValue(String)
}

/// # Trace ID Format
/// A trace_id consists of three numbers separated by hyphens.
/// For example, `1-58406520-a006649127e371903a2de979`. This includes:
/// - The version number, that is, 1.
/// - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**. For example, 10:00AM December 1st, 2016 PST in epoch time is `1480615200 seconds`, or `58406520` in hexadecimal digits.
/// - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.
struct TraceId: CustomStringConvertible {
    /// The version number, that is, 1.
    let version: UInt = 1
    /// The time of the original request, in Unix epoch time, in 8 hexadecimal digits.
    /// For example, 10:00AM December 1st, 2016 PST in epoch time is 1480615200 seconds, or 58406520 in hexadecimal digits.
    let date: Double
    /// A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.
    let id: String

    var description: String {
        "\(version)-\(String(format:"%02x", Int(date)))-\(id)"
    }
}

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
/// - See: [AWS X-Ray concepts - Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)
struct TracingHeaderValue {
    /// root trace ID
    let root: String  // TODO: TraceId type?
    /// parent segment ID
    let parentId: String?
    /// sampling decision
    let sampled: Bool
}

extension TracingHeaderValue {
    init(string: String) throws {
        // TODO: cleanup, add test case for string with ";" but without "="
        let values = string.split(separator: ";").map { $0.split(separator: "=") }
        let numValues = values.count
        guard
            numValues >= 2, numValues <= 3,
            values[0][0] == "Root",
            values[numValues - 1][0] == "Sampled"
        else {
            throw XRayRecorderTraceIdError.invalidTracingHeaderValue(string)
        }
        let rootValue = String(values[0][1])
        let sampledValue = values[numValues - 1][1]
        guard
            sampledValue == "1" || sampledValue == "0"
        else {
            throw XRayRecorderTraceIdError.invalidTracingHeaderValue(string)
        }
        self.root = rootValue
        if values[1][0] == "Parent" {
            self.parentId = String(values[1][1])
        } else {
            self.parentId = nil
        }
        self.sampled = sampledValue == "1"
    }
}
