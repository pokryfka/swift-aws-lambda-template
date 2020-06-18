import AWSXRay
import AsyncHTTPClient
import Logging
import NIO

import struct Foundation.Data
import class Foundation.JSONEncoder

extension JSONEncoder {
    fileprivate func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

class XRayEmmiter: Emmiter {
    let eventLoop: EventLoop
    private let httpClient: HTTPClient
    private let xray: XRay

    private lazy var logger = Logger(label: "XRayEmmiter")

    init(eventLoop: EventLoop, endpoint: String? = nil) {
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

    func send(segments: [Segment]) -> EventLoopFuture<Void> {
        do {
            let documents = try segments.map { try jsonEncoder.encode($0) as String }
            logger.info("Sending documents...\(documents.reduce("") { "\($0)\n\($1)" } )")
            let segmentRequest = XRay.PutTraceSegmentsRequest(traceSegmentDocuments: documents)
            return xray.putTraceSegments(segmentRequest)
                .map { _ in }
                .recover { error in
                    // log the error but do not fail
                    self.logger.error("Failed to send documents: \(error)")
                }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
