import AWSLambdaRuntimeCore
import AWSLambdaUtils
import AWSXRaySDK
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

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        let response: Out
        do {
            response = try context.tracer.segment(name: "HelloWorldAPIPerfHandler", baggage: context.baggage) { segment in
                segment.setHTTPRequest(method: event.context.http.method.rawValue,
                                       url: "https://\(event.context.domainName)\(event.context.http.path)",
                                       userAgent: event.context.http.userAgent,
                                       clientIP: event.context.http.sourceIp)
                segment.setAnnotation(event.context.stage, forKey: "stage")
                let input: HelloWorldIn
                if let body = event.body {
                    input = try segment.subsegment(name: "DecodePayload") { _ in
                        try self.decoder.decode(HelloWorldIn.self, from: ByteBuffer(string: body))
                    }
                } else {
                    input = HelloWorldIn(name: nil, hour: nil)
                }
                let output = HelloWorldOut(message: try greeting(atHour: input.hour), name: input.name)
                var body = try segment.subsegment(name: "EncodeResult") { _ in
                    try self.encoder.encode(output, using: context.allocator)
                }
                let contentLength = body.readableBytes
                let out = APIGateway.V2.Response(
                    statusCode: HTTPResponseStatus.ok,
                    headers: ["Content-Type": "application/json"],
                    body: body.readString(length: contentLength)
                )
                segment.setHTTPResponse(status: out.statusCode.code, contentLength: UInt(contentLength))
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
