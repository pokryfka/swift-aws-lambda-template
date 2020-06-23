import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import Backtrace
import HelloWorld
import NIO

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

Backtrace.install()

extension JSONDecoder {
    fileprivate func decode<T: Decodable>(type: T.Type, from string: String) throws -> T {
        try decode(type, from: Data(string.utf8))
    }
}

extension JSONEncoder {
    fileprivate func encode<T: Encodable>(value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private struct HelloWorldIn: Decodable {
    let secondsFromGMT: Int
}

private struct HelloWorldOut: Encodable {
    let now: Date
    let secondsFromGMT: Int
    let hour: Int
    let message: Greeting
}

private struct HelloWorldAPIHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.Request
    typealias Out = APIGateway.Response

    private let jsonDecoder = JSONDecoder()

    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let recorder = XRayRecorder()
    private let emmiter: XRayEmmiter

    init(eventLoop: EventLoop) {
        emmiter = XRayEmmiter(eventLoop: eventLoop, endpoint: Lambda.env("XRAY_ENDPOINT"))
    }

    private func sendXRaySegments() -> EventLoopFuture<Void> {
        emmiter.send(segments: recorder.segments)
    }

    func shutdown(context: Lambda.ShutdownContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        do {
            let traceHeader = try? XRayRecorder.TraceHeader(string: context.traceID)
            let response = try recorder.segment(
                name: "HelloWorldAPIHandler",
                traceHeader: traceHeader
            ) { segment -> Out in
                segment.addMetadata(["debug": ["test": "Test"]])
                let now = Date()
                let secondsFromGMT: Int = try segment.subSegment(name: "Parsing Input") { _ in
                    if let body = event.body {
                        let input = try jsonDecoder.decode(type: HelloWorldIn.self, from: body)
                        return input.secondsFromGMT
                    } else {
                        return 0
                    }
                }
                segment.addAnnotation("secondsFromGMT", value: secondsFromGMT)

                let greetingHour = try segment.subSegment(name: "Greeting Hour") { _ in
                    try hour(onDate: now, inTimeZoneWithSecondsFromGMT: secondsFromGMT)
                }
                let greetingMessage = try segment.subSegment(name: "Greeting Message") { _ in
                    try greeting(atHour: greetingHour)
                }

                let output = HelloWorldOut(
                    now: now,
                    secondsFromGMT: secondsFromGMT,
                    hour: greetingHour,
                    message: greetingMessage
                )

                let encodingSegment = segment.beginSubSegment(name: "Encoding Response")
                let body: String? = try jsonEncoder.encode(value: output)
                let response = APIGateway.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body)
                encodingSegment.end()
                return response
            }
            return context.eventLoop.makeSucceededFuture(())
                .flatMap { self.sendXRaySegments() }
                .map { _ in response }
        } catch let error as DecodingError {
            context.logger.error("DecodingError: \(error.localizedDescription)")
            let response = APIGateway.Response(statusCode: HTTPResponseStatus.badRequest)
            return context.eventLoop.makeSucceededFuture(response)
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

Lambda.run { context in HelloWorldAPIHandler(eventLoop: context.eventLoop) }
