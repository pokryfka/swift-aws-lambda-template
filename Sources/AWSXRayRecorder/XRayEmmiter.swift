import AWSXRay
import AsyncHTTPClient
import Logging
import NIO

public class XRayEmmiter {
    let eventLoop: EventLoop
    private let httpClient: HTTPClient
    private let xray: XRay

    private lazy var logger = Logger(label: "XRayEmmiter")

    public init(eventLoop: EventLoop, endpoint: String? = nil) {
        self.eventLoop = eventLoop
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        if let endpoint = endpoint {
            xray = XRay(endpoint: endpoint, httpClientProvider: .shared(httpClient))
        } else {
            xray = XRay(httpClientProvider: .shared(httpClient))
        }
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    public func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void> {
        guard segments.isEmpty == false
        else {
            return eventLoop.makeSucceededFuture(())
        }

        let documents = segments.filter { $0.isReady }.compactMap { try? $0.JSONString() }
        logger.info("Sending documents...\(documents.reduce("") { "\($0)\n\($1)" } )")
        let segmentRequest = XRay.PutTraceSegmentsRequest(traceSegmentDocuments: documents)
        return xray.putTraceSegments(segmentRequest)
            .map { result in
                self.logger.info("Result: \(result)")
            }
            .recover { error in
                // log the error but do not fail...
                self.logger.error("Failed to send documents: \(error)")
            }
    }
}

extension XRayRecorder.Segment {
    fileprivate var isReady: Bool {
        endTime != nil
    }
}
