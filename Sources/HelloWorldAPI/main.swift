import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import AWSXRayRecorderLambda
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
    typealias In = APIGateway.Request
    typealias Out = APIGateway.Response

    private let recorder = XRayRecorder()

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        let response: APIGateway.Response
        do {
            response = try recorder.segment(name: "HelloWorldAPIHandler", context: context) { segment in
                var tz: String?
                if let body = event.body {
                    let input = try self.decoder.decode(HelloWorldIn.self, from: ByteBuffer(string: body))
                    tz = input.tz
                }
                let greetingHour = try segment.subsegment(name: "Hour") { _ in try hour(inTimeZone: tz) }
                let greetingMessage = try segment.subsegment(name: "Greeting") { _ in
                    try greeting(atHour: greetingHour)
                }
                let output = HelloWorldOut(message: greetingMessage)
                var body = try self.encoder.encode(output, using: context.allocator)
                return APIGateway.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body.readString(length: body.readableBytes)
                )
            }
        } catch let error as DecodingError {
            let errorMessage = "DecodingError: \(error)"
            context.logger.error("\(errorMessage)")
            response = APIGateway.Response(statusCode: .badRequest, body: errorMessage)
        } catch DateError.invalidTimeZone(let identifier) {
            let errorMessage = "DateError.invalidTimeZone: \(identifier)"
            context.logger.error("\(errorMessage)")
            response = APIGateway.Response(statusCode: .badRequest, body: errorMessage)
        } catch {
            context.logger.error("AnError: \(error)")
            response = APIGateway.Response(statusCode: .internalServerError)
        }
        return recorder.flush(on: context.eventLoop)
            .map { _ in response }
    }
}

Lambda.run(HelloWorldAPIHandler())
