import AWSLambdaRuntimeCore
import AWSLambdaUtils
import AWSXRaySDK
import HelloWorld
import NIO

private struct HelloWorldIn: Decodable {
    let name: String?
    let hour: UInt?
}

private struct HelloWorldOut: Encodable {
    let message: Greeting
}

private struct HelloWorldAPIHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        context.logger.info("In:\n\(event)") // TODO: change to debug?
        let response: Out
        do {
            response = try context.tracer.segment(name: "HelloWorldAPIPerfHandler", baggage: context.baggage) { _ in
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
        return context.eventLoop.makeSucceededFuture(response)
    }
}

Lambda.run(HelloWorldAPIHandler())
