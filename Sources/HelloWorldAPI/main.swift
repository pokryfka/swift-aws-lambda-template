import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import AWSXRayRecorderLambda
import AWSXRayUDPEmitter
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
    private let emmiter = XRayUDPEmitter()

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        do {
            let response: APIGateway.Response = try recorder.segment(name: "HelloWorldAPIHandler", context: context) { segment in
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
                let response = APIGateway.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body.readString(length: body.readableBytes)
                )
                return response
            }
            return emmiter.send(segments: recorder.removeAll())
                .map { _ in response }
        } catch let error as DecodingError {
            context.logger.error("DecodingError: \(error)")
            let response = APIGateway.Response(statusCode: HTTPResponseStatus.badRequest)
            return emmiter.send(segments: recorder.removeAll())
                .map { _ in response }
        } catch {
            context.logger.error("AnError: \(error)")
            let response = APIGateway.Response(statusCode: HTTPResponseStatus.internalServerError)
            return emmiter.send(segments: recorder.removeAll())
                .map { _ in response }
        }
    }
}

Lambda.run(HelloWorldAPIHandler())
