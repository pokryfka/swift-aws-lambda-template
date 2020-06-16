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

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        // TODO: check if the region needs to be explicitly set? check env?
        xray = XRay(region: .useast1, httpClientProvider: .shared(httpClient))
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    func send(segments: [Segment]) -> EventLoopFuture<Void> {
        do {
            let documents = try segments.map { try jsonEncoder.encode($0) as String }
            logger.info("Sending documents...\(documents.reduce("") { "\($0)\n\($1)" } )")
            let segmentRequest = XRay.PutTraceSegmentsRequest(traceSegmentDocuments: documents)
            return xray.putTraceSegments(segmentRequest).map { _ in }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
