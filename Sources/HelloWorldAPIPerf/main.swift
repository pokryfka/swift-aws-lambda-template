// import AWSLambdaEvents
import AWSLambdaRuntimeCore
import AWSXRaySDK
import Backtrace
import HelloWorld
import NIO

Backtrace.install()

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
        let recorder = context.tracer
        let response: Out
        do {
            response = try recorder.segment(name: "HelloWorldAPIPerfHandler", baggage: context.baggage) { segment in
                var tz: String?
                if let body = event.body {
                    segment.setMetadata("\(body)", forKey: "in")
                    let input = try self.decoder.decode(HelloWorldIn.self, from: ByteBuffer(string: body))
                    tz = input.tz
                }
                let greetingHour = try segment.subsegment(name: "Hour") { _ in try hour(inTimeZone: tz) }
                let greetingMessage = try segment.subsegment(name: "Greeting") { _ in
                    try greeting(atHour: greetingHour)
                }
                let output = HelloWorldOut(message: greetingMessage)
                var body = try self.encoder.encode(output, using: context.allocator)
                let contentLength = body.readableBytes
                let out = APIGateway.V2.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body.readString(length: contentLength)
                )
                if let body = out.body {
                    segment.setMetadata("\(body)", forKey: "out")
                }
                return out
            }
        } catch let error as DecodingError {
            context.logger.error("DecodingError: \(error)")
            response = APIGateway.V2.Response(statusCode: .badRequest)
        } catch DateError.invalidTimeZone(let identifier) {
            context.logger.error("DateError.invalidTimeZone: \(identifier)")
            response = APIGateway.V2.Response(statusCode: .badRequest)
        } catch {
            context.logger.error("AnError: \(error)")
            response = APIGateway.V2.Response(statusCode: .internalServerError)
        }
        return context.eventLoop.makeSucceededFuture(response)
    }
}

Lambda.run(HelloWorldAPIHandler())
