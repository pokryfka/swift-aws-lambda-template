import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRaySDK
import HelloWorld
import NIO

private let recorder = XRayRecorder()
defer {
    recorder.shutdown()
}

private struct HelloWorldIn: Decodable {
    /// time zone identifier, default `UTC`
    let tz: String?
}

private struct HelloWorldOut: Encodable {
    let message: Greeting
}

private struct HelloWorldAPIHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        let traceContext: XRayRecorder.TraceContext = (try? .init(tracingHeader: context.traceID)) ?? .init()
        let response: Out
        do {
            response = try recorder.segment(name: "HelloWorldAPIPerfHandler", context: traceContext) { _ in
                // TODO: parse name and hour
//                if let body = event.body {
//                    let input = try self.decoder.decode(HelloWorldIn.self, from: ByteBuffer(string: body))
//                }
                let output = HelloWorldOut(message: .default)
                var body = try self.encoder.encode(output, using: context.allocator)
                let contentLength = body.readableBytes
                let out = APIGateway.V2.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body.readString(length: contentLength)
                )
                return out
            }
        } catch let error as DecodingError {
            context.logger.error("DecodingError: \(error)")
            response = APIGateway.V2.Response(statusCode: .badRequest)
        } catch {
            context.logger.error("AnError: \(error)")
            response = APIGateway.V2.Response(statusCode: .internalServerError)
        }
        // flush the tracer after each invocation and return the invocation result
        return recorder.flush(on: context.eventLoop)
            .map { _ in response }
    }
}

Lambda.run(HelloWorldAPIHandler())
