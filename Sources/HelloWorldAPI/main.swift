import AWSLambdaRuntimeCore
import AWSLambdaUtils
import HelloWorld
import NIO

private struct HelloWorldIn: Decodable {
    let name: String?
    let hour: Int?
}

private struct HelloWorldOut: Encodable {
    let message: Greeting
    let name: String?
}

private struct HelloWorldAPIHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response

    init(context: Lambda.InitializationContext) {
        context.logger.info("init")
    }

    func shutdown(context: AWSLambdaRuntimeCore.Lambda.ShutdownContext) -> NIO.EventLoopFuture<Void> {
        context.logger.info("shutdown")
        return context.eventLoop.makeSucceededFuture(())
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        context.logger.debug("handle \(event)")
        let response: Out
        do {
            let input: HelloWorldIn
            if let body = event.body {
                input = try decoder.decode(HelloWorldIn.self, from: ByteBuffer(string: body))
            } else {
                input = HelloWorldIn(name: nil, hour: nil)
            }
            let output = HelloWorldOut(message: try greeting(atHour: input.hour), name: input.name)
            var body = try encoder.encode(output, using: context.allocator)
            let contentLength = body.readableBytes
            response = APIGateway.V2.Response(
                statusCode: HTTPResponseStatus.ok,
                headers: ["Content-Type": "application/json"],
                body: body.readString(length: contentLength)
            )
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

Lambda.run(HelloWorldAPIHandler.init)
